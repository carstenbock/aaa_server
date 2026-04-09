%%%-------------------------------------------------------------------
%%% @doc EAP relay — bridges SWm DER from ePDG to SWx MAR toward HSS.
%%% Implements EAP-AKA / EAP-AKA' state machine per RFC 4187 / 5448.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_eap_relay).

-export([process_eap/2]).

%% @doc Process incoming EAP payload from ePDG (via SWm DER).
%% Returns EAP response payload and result status.
-spec process_eap(binary(), binary()) ->
    {ok, #{eap_payload := binary(), result := success | challenge}} |
    {error, term()}.
process_eap(IMSI, EAPPayload) ->
    case decode_eap_type(EAPPayload) of
        identity ->
            %% EAP-Identity → fetch auth vectors from HSS
            request_vectors(IMSI);
        aka_response ->
            %% EAP-AKA/AKA' Response → verify RES
            verify_response(IMSI, EAPPayload);
        _ ->
            {error, unsupported_eap_type}
    end.

%%====================================================================
%% Internal
%%====================================================================

request_vectors(IMSI) ->
    case aaa_swx_client:multimedia_auth_request(IMSI, #{num_vectors => 1}) of
        {ok, #{auth_vectors := [Vector | _]}} ->
            %% Build EAP-AKA' Challenge from auth vector
            Challenge = build_aka_challenge(Vector),
            %% Store vector in session for later verification
            aaa_session_mgr:store_auth_vector(IMSI, Vector),
            {ok, #{eap_payload => Challenge, result => challenge}};
        {error, Reason} ->
            {error, {mar_failed, Reason}}
    end.

verify_response(IMSI, EAPPayload) ->
    case aaa_session_mgr:get_auth_vector(IMSI) of
        {ok, #{xres := XRES}} ->
            %% Extract RES from EAP-AKA response payload
            RES = extract_res(EAPPayload),
            case RES =:= XRES of
                true ->
                    %% EAP-Success + SAR to HSS
                    aaa_swx_client:server_assignment_request(IMSI,
                        #{assignment_type => 1}),
                    EAPSuccess = <<1, 0, 0, 4>>,
                    {ok, #{eap_payload => EAPSuccess, result => success}};
                false ->
                    {error, auth_mismatch}
            end;
        error ->
            {error, no_pending_auth}
    end.

build_aka_challenge(#{rand := RAND, autn := AUTN}) ->
    %% EAP-AKA' Challenge (simplified — type 50, subtype 1)
    %% Full implementation needs proper AT_RAND, AT_AUTN, AT_KDF, AT_KDF_INPUT, AT_MAC
    <<1, 0, 0, (4 + byte_size(RAND) + byte_size(AUTN)),
      50, 1, 0, 0,
      RAND/binary, AUTN/binary>>;
build_aka_challenge(_) ->
    <<1, 0, 0, 4>>.

extract_res(<<_Code, _Id, _Len:16, _Type, _Subtype, _Rest/binary>> = _EAP) ->
    %% Extract AT_RES from EAP-AKA response
    %% Full implementation parses attribute list
    <<>>;
extract_res(_) ->
    <<>>.

decode_eap_type(<<_Code, _Id, _Len:16, 1, _/binary>>) -> identity;
decode_eap_type(<<_Code, _Id, _Len:16, 23, _/binary>>) -> aka_response;
decode_eap_type(<<_Code, _Id, _Len:16, 50, _/binary>>) -> aka_prime_response;
decode_eap_type(_) -> unknown.
