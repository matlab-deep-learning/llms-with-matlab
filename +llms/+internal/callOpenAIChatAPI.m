function [text, message, response] = callOpenAIChatAPI(messages, functions, nvp)
% This function is undocumented and will change in a future release

%callOpenAIChatAPI Calls the openAI chat completions API.
%
%   MESSAGES and FUNCTIONS should be structs matching the json format 
%   required by the OpenAI Chat Completions API.
%   Ref: https://platform.openai.com/docs/guides/gpt/chat-completions-api
%
%   Currently, the supported NVP are, including the equivalent name in the API:              
%    - FunctionCall (function_call)             
%    - ModelName (model)
%    - Temperature (temperature)
%    - TopProbabilityMass (top_p)        
%    - NumCompletions (n)
%    - StopSequences (stop)           
%    - MaxNumTokens (max_tokens)          
%    - PresencePenalty (presence_penalty)                         
%    - FrequencyPenalty (frequence_penalty)                    
%    - ApiKey 
%   More details on the parameters: https://platform.openai.com/docs/api-reference/chat/create

%   Copyright 2023 The MathWorks, Inc.

arguments
    messages
    functions
    nvp.FunctionCall
    nvp.ModelName
    nvp.Temperature
    nvp.TopProbabilityMass
    nvp.NumCompletions
    nvp.StopSequences
    nvp.MaxNumTokens
    nvp.PresencePenalty
    nvp.FrequencyPenalty
    nvp.ApiKey
end

    END_POINT = "https://api.openai.com/v1/chat/completions";

    parameters = buildParametersCall(messages, functions, nvp);

    response = llms.internal.sendRequest(parameters,nvp.ApiKey, END_POINT);

    if response.StatusCode=="OK"
        message = response.Body.Data.choices(1).message;
        if isfield(message, "function_call")
            text = "";
            message.function_call.arguments = message.function_call.arguments;
        else
            text = string(message.content);
        end
    else
        text = "";
        message = struct();
    end
end

function parameters = buildParametersCall(messages, functions, nvp)
    % Builds a struct in the format that is expected by the API, combining
    % MESSAGES, FUNCTIONS and parameters in NVP.

    parameters = struct();
    parameters.messages = messages;
    if ~isempty(functions)
        parameters.functions = functions;
    end

    if ~isempty(nvp.FunctionCall)
        parameters.function_call = nvp.FunctionCall;
    end

    parameters.model = nvp.ModelName;

    dict = mapNVPToParameters;
    
    nvpOptions = keys(dict);
    for i=1:length(nvpOptions)
        if isfield(nvp, nvpOptions(i))
            parameters.(dict(nvpOptions(i))) = nvp.(nvpOptions(i));
        end
    end
end

function dict = mapNVPToParameters()
    dict = dictionary();
    dict("Temperature") = "temperature";
    dict("TopProbabilityMass") = "top_p";
    dict("NumCompletions") = "n";
    dict("StopSequences") = "stop";
    dict("MaxNumTokens") = "max_tokens";
    dict("PresencePenalty") = "presence_penalty";
    dict("FrequencyPenalty ") = "frequency_penalty";
end