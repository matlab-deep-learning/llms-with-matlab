classdef(Sealed) azureChat < llms.internal.textGenerator & llms.internal.gptPenalties
%azureChat Chat completion API from Azure.
%
%   CHAT = azureChat(endpoint, deploymentID) creates an azureChat object with
%   the endpoint and deployment ID path parameters required by Azure to
%   establish the connection.
%
%   CHAT = azureChat(__,systemPrompt) creates an azureChat object with the
%   specified system prompt.
%
%   CHAT = azureChat(__,Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%   Temperature             - Temperature value for controlling the randomness
%                             of the output. Default value is 1; higher values
%                             increase the randomness (in some sense,
%                             the “creativity”) of outputs, lower values
%                             reduce it. Setting Temperature=0 removes
%                             randomness from the output altogether.
%
%   TopP      - Top probability mass value for controlling the
%                             diversity of the output. Default value is 1;
%                             lower values imply that only the more likely
%                             words can appear in any particular place.
%                             This is also known as top-p sampling.
%
%   StopSequences           - Vector of strings that when encountered, will
%                             stop the generation of tokens. Default
%                             value is empty.
%                             Example: ["The end.", "And that's all she wrote."]
%
%   ResponseFormat          - The format of response the model returns.
%                             "text" (default) | "json"
%
%   APIKey                  - The API key for accessing the OpenAI Chat API.
%
%   PresencePenalty         - Penalty value for using a token in the response
%                             that has already been used. Default value is 0.
%                             Higher values reduce repetition of words in the output.
%
%   FrequencyPenalty        - Penalty value for using a token that is frequent
%                             in the output. Default value is 0.
%                             Higher values reduce repetition of words in the output.
%
%   StreamFun               - Function to callback when streaming the result
%
%   TimeOut                 - Connection Timeout in seconds. Default value is 10.
%
%   Tools                   - A list of tools the model can call.
%
%   API Version             - The API version to use for this model.
%                             "2024-02-01" (default) | "2023-05-15" | "2024-05-01-preview" | ...
%                             "2024-04-01-preview" | "2024-03-01-preview"
%
%
%
%   azureChat Functions:
%       azureChat            - Chat completion API from OpenAI.
%       generate             - Generate a response using the azureChat instance.
%
%   azureChat Properties:
%       Temperature          - Temperature of generation.
%
%       TopP   - Top probability mass to consider for generation.
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
%       FunctionNames        - Names of the functions that the model can
%                              request calls.
%
%       ResponseFormat       - Specifies the response format, "text" or "json".
%
%       TimeOut              - Connection Timeout in seconds.
%

% Copyright 2023-2024 The MathWorks, Inc.

    properties(SetAccess=private)
        Endpoint     (1,1) string
        DeploymentID (1,1) string
        APIVersion   (1,1) string
    end

    methods
        function this = azureChat(endpoint, deploymentID, systemPrompt, nvp)
            arguments
                endpoint                           {mustBeTextScalar}
                deploymentID                       {mustBeTextScalar}
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Tools                    (1,:) {mustBeA(nvp.Tools, "openAIFunction")} = openAIFunction.empty
                nvp.APIVersion               (1,1) {mustBeAPIVersion} = "2024-02-01"
                nvp.Temperature                    {llms.utils.mustBeValidTemperature} = 1
                nvp.TopP             {llms.utils.mustBeValidTopP} = 1
                nvp.StopSequences                  {llms.utils.mustBeValidStop} = {}
                nvp.ResponseFormat           (1,1) string {mustBeMember(nvp.ResponseFormat,["text","json"])} = "text"
                nvp.APIKey                         {mustBeNonzeroLengthTextScalar}
                nvp.PresencePenalty                {llms.utils.mustBeValidPenalty} = 0
                nvp.FrequencyPenalty               {llms.utils.mustBeValidPenalty} = 0
                nvp.TimeOut                  (1,1) {mustBeReal,mustBePositive} = 10
                nvp.StreamFun                (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
            end

            if isfield(nvp,"StreamFun")
                this.StreamFun = nvp.StreamFun;
            else
                this.StreamFun = [];
            end

            if isempty(nvp.Tools)
                this.Tools = [];
                this.FunctionsStruct = [];
                this.FunctionNames = [];
            else
                this.Tools = nvp.Tools;
                [this.FunctionsStruct, this.FunctionNames] = functionAsStruct(nvp.Tools);
            end

            if ~isempty(systemPrompt)
                systemPrompt = string(systemPrompt);
                if ~(strlength(systemPrompt)==0)
                   this.SystemPrompt = {struct("role", "system", "content", systemPrompt)};
                end
            end

            this.Endpoint = endpoint;
            this.DeploymentID = deploymentID;
            this.APIVersion = nvp.APIVersion;
            this.ResponseFormat = nvp.ResponseFormat;
            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.StopSequences = nvp.StopSequences;
            this.PresencePenalty = nvp.PresencePenalty;
            this.FrequencyPenalty = nvp.FrequencyPenalty;
            this.APIKey = llms.internal.getApiKeyFromNvpOrEnv(nvp,"AZURE_OPENAI_API_KEY");
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
                this                    (1,1) azureChat
                messages                (1,1) {mustBeValidMsgs}
                nvp.NumCompletions      (1,1) {mustBePositive, mustBeInteger} = 1
                nvp.MaxNumTokens        (1,1) {mustBePositive} = inf
                nvp.ToolChoice          {mustBeValidFunctionCall(this, nvp.ToolChoice)} = []
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

            toolChoice = convertToolChoice(this, nvp.ToolChoice);
            try
                [text, message, response] = llms.internal.callAzureChatAPI(this.Endpoint, ...
                    this.DeploymentID, messagesStruct, this.FunctionsStruct, ...
                    ToolChoice=toolChoice, APIVersion = this.APIVersion, Temperature=this.Temperature, ...
                    TopP=this.TopP, NumCompletions=nvp.NumCompletions,...
                    StopSequences=this.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                    PresencePenalty=this.PresencePenalty, FrequencyPenalty=this.FrequencyPenalty, ...
                    ResponseFormat=this.ResponseFormat,Seed=nvp.Seed, ...
                    APIKey=this.APIKey,TimeOut=this.TimeOut, StreamFun=this.StreamFun);
            catch ME
                if ismember(ME.identifier,...
                    ["MATLAB:webservices:UnknownHost","MATLAB:webservices:Timeout"])
                    % throw(ME)would still print a long stack trace, from
                    % ME.cause.stack. We cannot change ME.cause, so we
                    % throw a new error:
                    error(ME.identifier,ME.message);
                end
                rethrow(ME);
            end

            if isfield(response.Body.Data,"error")
                err = response.Body.Data.error.message;
                error("llms:apiReturnedError",llms.utils.errorMessageCatalog.getMessage("llms:apiReturnedError",err));
            end
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
            elseif toolChoice ~= "auto"
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
if isa(value, "messageHistory")
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

function mustBeAPIVersion(model)
    mustBeMember(model,llms.azure.apiVersions);
end
