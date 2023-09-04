function response = sendRequest(parameters, token, endpoint, consumer)
    % Define the headers for the API request
    
    headers = matlab.net.http.HeaderField('Content-Type', 'application/json');
    headers(2) = matlab.net.http.HeaderField('Authorization', 'Bearer ' + string(token));
    % Define the request message
    request = matlab.net.http.RequestMessage('post',headers,parameters);
    % Send the request and store the response
    if nargin==3
        response = send(request, matlab.net.URI(endpoint));
    else
        response = send(request, matlab.net.URI(endpoint),[],consumer);
    end   
end

