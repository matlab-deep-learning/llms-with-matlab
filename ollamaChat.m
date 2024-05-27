classdef(Sealed) ollamaChat < llms.internal.textGenerator
%ollamaChat Chat completion API from Azure.
%
%   CHAT = ollamaChat(modelName) creates an ollamaChat object for the given model.
%
%   CHAT = ollamaChat(__,systemPrompt) creates an ollamaChat object with the
%   specified system prompt.
%
%   CHAT = ollamaChat(__,Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%   Temperature             - Temperature value for controlling the randomness
%                             of the output. Default value depends on the model;
%                             if not specified in the model, defaults to 0.8.
%
%   TODO: TopK and TopP, how do they relate to this?
%   TopProbabilityMass      - Top probability mass value for controlling the
%                             diversity of the output. Default value is 1.
%
%   StopSequences           - Vector of strings that when encountered, will
%                             stop the generation of tokens. Default
%                             value is empty.
%
%   ResponseFormat          - The format of response the model returns.
%                             "text" (default) | "json"
%
%   Seed - TODO: Seems to have no effect whatsoever (tested via curl) - cf. https://github.com/ollama/ollama/issues/4660
%
%   Mirostat - 0/1/2, eta, tau
%
%   RepeatLastN - find a better name! “Sets how far back for the model to look back to prevent repetition. (Default: 64, 0 = disabled, -1 = num_ctx)”
%
%   RepeatPenalty
%
%   TailFreeSamplingZ
%
%   MaxNumTokens
%
%   StreamFun               - Function to callback when streaming the
%                             result
%
%   TimeOut                 - Connection Timeout in seconds (default: 10 secs)
%
%
%
%   ollamaChat Functions:
%       ollamaChat            - Chat completion API from OpenAI.
%       generate             - Generate a response using the ollamaChat instance.
%
%   ollamaChat Properties: TODO TODO
%       Temperature          - Temperature of generation.
%
%       TopProbabilityMass   - Top probability mass to consider for generation.
%
%       StopSequences        - Sequences to stop the generation of tokens.
%
%       PresencePenalty      - Penalty for using a token in the
%                              response that has already been used.
%
%       FrequencyPenalty     - Penalty for using a token that is
%                              frequent in the training data.
%
%       SystemPrompt         - System prompt.
%
%       ResponseFormat       - Specifies the response format, text or json
%
%       TimeOut              - Connection Timeout in seconds (default: 10 secs)
%

% Copyright 2024 The MathWorks, Inc.

    properties(SetAccess=private)
        Model     (1,1) string
    end

    methods
        function this = ollamaChat(modelName, systemPrompt, nvp)
            arguments
                modelName                          {mustBeTextScalar}
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Temperature                    {llms.utils.mustBeValidTemperature} = 1
                nvp.TopProbabilityMass             {llms.utils.mustBeValidTopP} = 1
                nvp.StopSequences                  {llms.utils.mustBeValidStop} = {}
                nvp.ResponseFormat           (1,1) string {mustBeMember(nvp.ResponseFormat,["text","json"])} = "text"
                nvp.TimeOut                  (1,1) {mustBeReal,mustBePositive} = 10
                nvp.StreamFun                (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
            end

            if isfield(nvp,"StreamFun")
                this.StreamFun = nvp.StreamFun;
            else
                this.StreamFun = [];
            end

            if ~isempty(systemPrompt)
                systemPrompt = string(systemPrompt);
                if ~(strlength(systemPrompt)==0)
                   this.SystemPrompt = {struct("role", "system", "content", systemPrompt)};
                end
            end

            this.Model = modelName;
            this.ResponseFormat = nvp.ResponseFormat;
            this.Temperature = nvp.Temperature;
            this.TopProbabilityMass = nvp.TopProbabilityMass;
            this.StopSequences = nvp.StopSequences;
            this.TimeOut = nvp.TimeOut;
        end

        function [text, message, response] = generate(this, messages, nvp)
            %generate   Generate a response using the azureChat instance.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(CHAT, MESSAGES) generates a response
            %   with the specified MESSAGES.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(__, Name=Value) specifies additional options
            %   using one or more name-value arguments:
            %
            %       NumCompletions   - Number of completions to generate.
            %                          Default value is 1.
            %
            %       MaxNumTokens     - Maximum number of tokens in the generated response.
            %                          Default value is inf.
            %
            %       ToolChoice       - Function to execute. 'none', 'auto',
            %                          or specify the function to call.
            %
            %       Seed             - An integer value to use to obtain
            %                          reproducible responses
            %
            % Currently, GPT-4 Turbo with vision does not support the message.name
            % parameter, functions/tools, response_format parameter, stop
            % sequences, and max_tokens

            arguments
                this                    (1,1) ollamaChat
                messages                (1,1) {mustBeValidMsgs}
                nvp.NumCompletions      (1,1) {mustBePositive, mustBeInteger} = 1
                nvp.MaxNumTokens        (1,1) {mustBePositive} = inf
                nvp.Seed                {mustBeIntegerOrEmpty(nvp.Seed)} = []
            end

            if isstring(messages) && isscalar(messages)
                messagesStruct = {struct("role", "user", "content", messages)};
            else
                messagesStruct = messages.Messages;
            end

            if ~isempty(this.SystemPrompt)
                messagesStruct = horzcat(this.SystemPrompt, messagesStruct);
            end

            [text, message, response] = llms.internal.callOllamaChatAPI(...
                this.Model, messagesStruct, ...
                Temperature=this.Temperature, ...
                NumCompletions=nvp.NumCompletions,...
                StopSequences=this.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                ResponseFormat=this.ResponseFormat,Seed=nvp.Seed, ...
                TimeOut=this.TimeOut, StreamFun=this.StreamFun);
        end
    end

    methods(Hidden)
        function mustBeValidFunctionCall(this, functionCall)
            if ~isempty(functionCall)
                mustBeTextScalar(functionCall);
                if isempty(this.FunctionNames)
                    error("llms:mustSetFunctionsForCall", llms.utils.errorMessageCatalog.getMessage("llms:mustSetFunctionsForCall"));
                end
                mustBeMember(functionCall, ["none","auto", this.FunctionNames]);
            end
        end

        function toolChoice = convertToolChoice(this, toolChoice)
            % if toolChoice is empty
            if isempty(toolChoice)
                % if Tools is not empty, the default is 'auto'.
                if ~isempty(this.Tools)
                    toolChoice = "auto";
                end
            elseif ToolChoice ~= "auto"
                % if toolChoice is not empty, then it must be in the format
                % {"type": "function", "function": {"name": "my_function"}}
                toolChoice = struct("type","function","function",struct("name",toolChoice));
            end

        end
    end
end

function mustBeNonzeroLengthTextScalar(content)
mustBeNonzeroLengthText(content)
mustBeTextScalar(content)
end

function [functionsStruct, functionNames] = functionAsStruct(functions)
numFunctions = numel(functions);
functionsStruct = cell(1, numFunctions);
functionNames = strings(1, numFunctions);

for i = 1:numFunctions
    functionsStruct{i} = struct('type','function', ...
        'function',encodeStruct(functions(i))) ;
    functionNames(i) = functions(i).FunctionName;
end
end

function mustBeValidMsgs(value)
if isa(value, "openAIMessages")
    if numel(value.Messages) == 0
        error("llms:mustHaveMessages", llms.utils.errorMessageCatalog.getMessage("llms:mustHaveMessages"));
    end
else
    try
        llms.utils.mustBeNonzeroLengthTextScalar(value);
    catch ME
        error("llms:mustBeMessagesOrTxt", llms.utils.errorMessageCatalog.getMessage("llms:mustBeMessagesOrTxt"));
    end
end
end

function mustBeIntegerOrEmpty(value)
    if ~isempty(value)
        mustBeInteger(value)
    end
end