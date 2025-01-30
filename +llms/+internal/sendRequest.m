function [response, streamedText] = sendRequest(parameters, token, endpoint, timeout, streamFun)
% This function is undocumented and will change in a future release

%sendRequest Sends a request to an ENDPOINT using PARAMETERS and
%   api key TOKEN. TIMEOUT is the number of seconds to wait for initial
%   server connection. STREAMFUN is an optional callback function.

%   Copyright 2023-2025 The MathWorks, Inc.

arguments
    parameters
    token
    endpoint
    timeout
    streamFun = []
end

% Define the headers for the API request

headers = matlab.net.http.HeaderField('Content-Type', 'application/json');
if ~isempty(token)
    headers = [headers ...
        matlab.net.http.HeaderField('Authorization', "Bearer " + token)...
        matlab.net.http.HeaderField('api-key',token)];
end

% Define the request message
request = matlab.net.http.RequestMessage('post',headers,parameters);

% set the timeout
httpOpts = matlab.net.http.HTTPOptions;
httpOpts.ConnectTimeout = timeout;
httpOpts.ResponseTimeout = timeout;

% Send the request and store the response
if isempty(streamFun)
    response = send(request, matlab.net.URI(endpoint),httpOpts);
    streamedText = "";
else
    % User defined a stream callback function
    consumer = llms.stream.responseStreamer(streamFun);
    response = send(request, matlab.net.URI(endpoint),httpOpts,consumer);
    streamedText = consumer.ResponseText;
end

% When the server sends jsonl or ndjson back, we do not get the automatic conversion.
if isnumeric(response.Body.Data)
    txt = native2unicode(response.Body.Data.',"UTF-8");
    % convert to JSON array
    json = "[" + replace(strtrim(txt),newline,',') + "]";
    try
        response.Body.Data = jsondecode(json);
    end
end
end
