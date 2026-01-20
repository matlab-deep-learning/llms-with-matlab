function [response, streamedText] = sendGeminiRequest(parameters, apiKey, endpoint, timeout, streamFun)
%sendGeminiRequest Send a request to the Google Gemini API
%
%   [RESPONSE, STREAMEDTEXT] = sendGeminiRequest(PARAMETERS, APIKEY, ENDPOINT, TIMEOUT, STREAMFUN)
%   sends a POST request to the Gemini API endpoint.
%
%   Gemini uses x-goog-api-key header for authentication (not Bearer token).

%   Copyright 2025 The MathWorks, Inc.

arguments
    parameters
    apiKey
    endpoint
    timeout
    streamFun = []
end

% Define the headers for the Gemini API request
% Gemini uses x-goog-api-key header for authentication
headers = matlab.net.http.HeaderField('Content-Type', 'application/json');
headers = [headers ...
    matlab.net.http.HeaderField('x-goog-api-key', apiKey)];

% Define the request message
request = matlab.net.http.RequestMessage('post', headers, parameters);

% Set the timeout
httpOpts = matlab.net.http.HTTPOptions;
httpOpts.ConnectTimeout = timeout;
httpOpts.ResponseTimeout = timeout;

% Send the request
if isempty(streamFun)
    % Non-streaming request
    response = send(request, matlab.net.URI(endpoint), httpOpts);
    streamedText = "";
else
    % Streaming request - add alt=sse to get Server-Sent Events format
    % This enables true real-time streaming with BinaryConsumer
    if contains(endpoint, "?")
        sseEndpoint = endpoint + "&alt=sse";
    else
        sseEndpoint = endpoint + "?alt=sse";
    end

    consumer = llms.stream.geminiResponseStreamer(streamFun);
    response = send(request, matlab.net.URI(sseEndpoint), httpOpts, consumer);
    streamedText = consumer.ResponseText;
end

% Handle raw byte response (when receiving non-JSON)
if isnumeric(response.Body.Data)
    txt = native2unicode(response.Body.Data.', "UTF-8");
    try
        response.Body.Data = jsondecode(txt);
    catch
        % If single JSON fails, try parsing as newline-delimited JSON
        json = "[" + replace(strtrim(txt), newline, ',') + "]";
        try
            response.Body.Data = jsondecode(json);
        end
    end
end

end
