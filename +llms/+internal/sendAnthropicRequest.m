function [response, streamedText] = sendAnthropicRequest(parameters, apiKey, endpoint, timeout, streamFun)
%sendAnthropicRequest Sends a request to Anthropic API endpoint
%
%   [RESPONSE, STREAMEDTEXT] = sendAnthropicRequest(PARAMETERS, APIKEY,
%   ENDPOINT, TIMEOUT, STREAMFUN) sends a POST request to the Anthropic API.
%
%   Anthropic uses different authentication headers than OpenAI:
%   - x-api-key: API key (not Bearer token)
%   - anthropic-version: API version string (required)
%
%   STREAMFUN is an optional callback function for streaming responses.

%   Copyright 2025 The MathWorks, Inc.

arguments
    parameters
    apiKey
    endpoint
    timeout
    streamFun = []
end

% Anthropic API version - using latest stable version
ANTHROPIC_VERSION = "2023-06-01";

% Define the headers for the Anthropic API request (row vector)
headers = [matlab.net.http.HeaderField('Content-Type', 'application/json') ...
           matlab.net.http.HeaderField('x-api-key', apiKey) ...
           matlab.net.http.HeaderField('anthropic-version', ANTHROPIC_VERSION)];

% Define the request message
request = matlab.net.http.RequestMessage('post', headers, parameters);

% Set the timeout
httpOpts = matlab.net.http.HTTPOptions;
httpOpts.ConnectTimeout = timeout;
httpOpts.ResponseTimeout = timeout;

% Send the request and store the response
if isempty(streamFun)
    response = send(request, matlab.net.URI(endpoint), httpOpts);
    streamedText = "";
else
    % User defined a stream callback function
    consumer = llms.stream.anthropicResponseStreamer(streamFun);
    response = send(request, matlab.net.URI(endpoint), httpOpts, consumer);
    streamedText = consumer.ResponseText;
end

% Handle non-JSON responses
if isnumeric(response.Body.Data)
    txt = native2unicode(response.Body.Data.', "UTF-8");
    try
        response.Body.Data = jsondecode(txt);
    end
end

end
