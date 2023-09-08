function response = sendRequest(parameters, token, endpoint)
% This function is undocumented and will change in a future release

%sendRequest Sends a request to an ENDPOINT using PARAMETERS and 
%   api key TOKEN.

%   Copyright 2023 The MathWorks, Inc.

    % Define the headers for the API request
    
    headers = [matlab.net.http.HeaderField('Content-Type', 'application/json')...
               matlab.net.http.HeaderField('Authorization', "Bearer " + token)];
    % Define the request message
    request = matlab.net.http.RequestMessage('post',headers,parameters);
    % Send the request and store the response
    response = send(request, matlab.net.URI(endpoint));
end

