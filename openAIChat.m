classdef(Sealed) openAIChat
% openAIChat - A class for interacting with the OpenAI Chat API.
%
%   openAIChat Properties:
%       ModelName            - The name of the model to use for chat completion.
%       Temperature          - Controls the randomness of the output. Higher values
%                              make the output more random.
%       TopProbabilityMass   - Controls the diversity of the output. Higher values
%                              make the output more diverse.
%       StopSequences        - A cell array of strings that, when encountered,
%                              will stop the generation of tokens.
%       PresencePenalty      - Controls the penalty for using a token in the
%                              response that has already been used.
%       FrequencyPenalty     - Controls the penalty for using a token that is
%                              frequent in the training data.
%       SystemPrompt         - The system prompt to start the conversation.
%
%   openAIChat Methods:
%       openAIChat - Create an openAIChat object.
%
%   openAIChat Constants:
%       AvailableModels - A list of available models for chat completion.

% Copyright 2023 The MathWorks, Inc.

    properties
        ModelName
        Temperature
        TopProbabilityMass
        StopSequences
        PresencePenalty
        FrequencyPenalty
        SystemPrompt = []
    end

    properties(SetAccess=private)
        Functions
        FunctionsNames
    end

    properties(Access=private)
        FunctionsStruct
        ApiKey    
    end

    properties(Constant)
        AvailableModels = ["gpt-4", "gpt-4-0613", "gpt-4-32k", "gpt-4-32k-0613",...
            "gpt-3.5-turbo", "gpt-3.5-turbo-0613", "gpt-3.5-turbo-16k",... 
            "gpt-3.5-turbo-16k-0613"]
    end

    methods
        function this = openAIChat(systemPrompt, nvp)
            %openAIChat - Create an openAIChat object.
            %
            %   chatObj = openAIChat(systemPrompt) creates an openAIChat object with the
            %   specified system prompt.
            %
            %   chatObj = openAIChat(systemPrompt, nvp) creates an openAIChat object with
            %   additional name-value pairs for customizing the chat behavior.
            %
            %   Name-Value Pair Arguments (Optional):
            %   'Functions'         - An array of openAIFunction objects representing
            %                         custom functions to be used during chat completions.
            %
            %   'ModelName'         - The name of the model to use for chat completion.
            %                         Default: "gpt-3.5-turbo"
            %
            %   'Temperature'       - The temperature value for controlling the randomness
            %                         of the output. Default: 1
            %
            %   'TopProbabilityMass'- The top probability mass value for controlling the
            %                         diversity of the output. Default: 1
            %
            %   'StopSequences'     - A cell array of strings that, when encountered, will
            %                         stop the generation of tokens. Default: {}
            %
            %   'ApiKey'            - The API key for accessing the OpenAI Chat API.
            %
            %   'PresencePenalty'   - The penalty value for using a token in the response
            %                         that has already been used. Default: 0
            %
            %   'FrequencyPenalty'  - The penalty value for using a token that is frequent
            %                         in the training data. Default: 0
            
            arguments
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Functions                (1,:) {mustBeA(nvp.Functions, "openAIFunction")} = openAIFunction.empty
                nvp.ModelName                (1,1) {mustBeValidModelName} = "gpt-3.5-turbo"
                nvp.Temperature              (1,1) {mustBeValidTemperature} = 1
                nvp.TopProbabilityMass       (1,1) {mustBeValidTopP} = 1
                nvp.StopSequences            (1,:) {mustBeValidStop} = {}
                nvp.ApiKey                   (1,1) {mustBeNonzeroLengthText} 
                nvp.PresencePenalty          (1,1) {mustBeValidPenalty} = 0
                nvp.FrequencyPenalty         (1,1) {mustBeValidPenalty} = 0
            end

            if ~isempty(nvp.Functions)
                this.Functions = nvp.Functions;
                [this.FunctionsStruct, this.FunctionsNames] = functionAsStruct(nvp.Functions);
            else
                this.Functions = [];
                this.FunctionsStruct = [];
                this.FunctionsNames = [];
            end
            
            if ~isempty(systemPrompt)
                systemPrompt = string(systemPrompt);
                if ~(strlength(systemPrompt)==0)
                   this.SystemPrompt = {struct("role", "system", "content", systemPrompt)};
                end
            end

            this.ModelName = nvp.ModelName;
            this.Temperature = nvp.Temperature;
            this.TopProbabilityMass = nvp.TopProbabilityMass;
            this.StopSequences = nvp.StopSequences;
            this.PresencePenalty = nvp.PresencePenalty;
            this.FrequencyPenalty = nvp.FrequencyPenalty;
            this.ApiKey = llms.internal.checkEnvOrNVP(nvp);
        end

        function [text, message, response] = generate(this, messages, nvp)
            %generate   Generate a response using the openAIChat instance.
            %   [TEXT, MESSAGE, RESPONSE] = generate(THIS, MESSAGES, NVP) generates a response
            %   using the openAIChat instance with the specified MESSAGES and optional
            %   name-value pair arguments.
            %
            %   Input Arguments:
            %     THIS               - openAIChat instance.
            %                          openAIChat object
            %
            %     MESSAGES           - Messages for generating the response.
            %                          struct array
            %
            %     NVP                - Name-value pair arguments:
            %       NumCompletions   - Number of completions to generate.
            %                          positive integer scalar (default: 1)
            %
            %       MaxNumTokens     - Maximum number of tokens in the generated response.
            %                          positive scalar (default: inf)
            %
            %       FunctionCall     - Function call to execute before generating the
            %                          response.
            %                          string scalar | character vector (default: [])
            %
            arguments
                this                    (1,1) openAIChat
                messages                (1,1) {mustBeValidMsgs}
                nvp.NumCompletions      (1,1) {mustBePositive, mustBeInteger} = 1
                nvp.MaxNumTokens        (1,1) {mustBePositive} = inf
                nvp.FunctionCall        {mustBeValidFunctionCall(this, nvp.FunctionCall)} = []
                nvp.Stream              (1,1) {logical} = false
            end

            functionCall = convertFunctionCall(this, nvp.FunctionCall);
            if isstring(messages) && isscalar(messages)
                messagesStruct = {struct("role", "user", "content", messages)};               
            else
                messagesStruct = messages.Messages;
            end

            if ~isempty(this.SystemPrompt)
                messagesStruct = horzcat(this.SystemPrompt, messagesStruct);
            end
            
            [text, message, response] = llms.internal.callOpenAIChatAPI(messagesStruct, this.FunctionsStruct,...
                ModelName=this.ModelName, FunctionCall=functionCall, Temperature=this.Temperature, ...
                TopProbabilityMass=this.TopProbabilityMass, NumCompletions=nvp.NumCompletions,...
                StopSequences=this.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                PresencePenalty=this.PresencePenalty, FrequencyPenalty=this.FrequencyPenalty, ...
                ApiKey=this.ApiKey);
        end

        function this = set.Temperature(this, temperature)
            arguments
                this openAIChat
                temperature (1,1) {mustBeValidTemperature}
            end
            this.Temperature = temperature;
        end

        function this = set.TopProbabilityMass(this,topP)
            arguments
                this openAIChat
                topP (1,1) {mustBeValidTopP}
            end
            this.TopProbabilityMass = topP;
        end

        function this = set.StopSequences(this,stop)
            arguments
                this openAIChat
                stop (1,:) {mustBeValidStop}
            end
            this.StopSequences = stop;
        end

        function this = set.PresencePenalty(this,penalty)
            arguments
                this openAIChat
                penalty (1,1) {mustBeValidPenalty}
            end
            this.PresencePenalty = penalty;
        end

        function this = set.FrequencyPenalty(this,penalty)
            arguments
                this openAIChat
                penalty (1,1) {mustBeValidPenalty}
            end
            this.FrequencyPenalty = penalty;
        end
    end

    methods(Hidden)
        function mustBeValidFunctionCall(this, functionCall)
            if ~isempty(functionCall)
                mustBeTextScalar(functionCall);
                if isempty(this.FunctionsNames)
                    error("llms:mustSetFunctionsForCall", llms.utils.errorMessageCatalog.getMessage("llms:mustSetFunctionsForCall"));
                end
                mustBeMember(functionCall, ["none","auto", this.FunctionsNames]);
            end
        end

        function functionCall = convertFunctionCall(this, functionCall)
            % If functionCall is not empty, then it must be in
            % the format {"name", functionCall}
            if ~isempty(functionCall)&&ismember(functionCall, this.FunctionsNames)
                functionCall = struct("name", functionCall);
            end

        end
    end
end


function [functionsStruct, functionsNames] = functionAsStruct(functions)
numFunctions = numel(functions);
functionsStruct = cell(1, numFunctions);
functionsNames = strings(1, numFunctions);

for i = 1:numFunctions
    functionsStruct{i} = encodeStruct(functions(i));
    functionsNames(i) = functions(i).FunctionName;
end
end

function mustBeValidMsgs(value)
if isa(value, "openAIMessages")
    if numel(value.Messages) == 0 
        error("llms:mustHaveMessages", llms.utils.errorMessageCatalog.getMessage("llms:mustHaveMessages"));
    end
else
    try 
        mustBeNonzeroLengthText(value);
    catch ME
        error("llms:mustBeMessagesOrTxt", llms.utils.errorMessageCatalog.getMessage("llms:mustBeMessagesOrTxt"));
    end
end
end

function mustBeValidPenalty(value)
mustBeLessThanOrEqual(value,2);
mustBeGreaterThanOrEqual(value,-2);
end

function mustBeValidTopP(value)
mustBeNonnegative(value);
mustBeLessThanOrEqual(value,1);
end

function mustBeValidModelName(value)
mustBeNonzeroLengthText(value);
mustBeMember(value,openAIChat.AvailableModels);
end

function mustBeValidTemperature(value)
mustBeNonnegative(value);
mustBeLessThanOrEqual(value,2)
end

function mustBeValidStop(value)
mustBeNonzeroLengthText(value);
% This restriction is set by the OpenAI api
if numel(value)>4
    error("llms:stopSequencesMustHaveMax4Elements", llms.utils.errorMessageCatalog.getMessage("llms:stopSequencesMustHaveMax4Elements"));
end
end