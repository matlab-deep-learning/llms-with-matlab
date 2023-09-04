function [text, message, response] = callOpenAIChatAPI(messages, functions, nvp)
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