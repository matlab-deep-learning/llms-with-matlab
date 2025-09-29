classdef(Sealed) azureChat < llms.internal.textGenerator & ...
    llms.internal.gptPenalties & llms.internal.hasTools & llms.internal.needsAPIKey
%azureChat Chat completion API from Azure.
%
%   CHAT = azureChat creates an azureChat object, with the parameters needed
%   to connect to Azure taken from the environment.
%
%   CHAT = azureChat(systemPrompt) creates an azureChat object with the
%   specified system prompt.
%
%   CHAT = azureChat(__,Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%   Endpoint                - The endpoint as defined in the Azure OpenAI Services
%                             interface. Needs to be specified or stored in the
%                             environment variable AZURE_OPENAI_ENDPOINT.
%
%   DeploymentID            - The deployment as defined in the Azure OpenAI Services
%                             interface. Needs to be specified or stored in the
%                             environment variable AZURE_OPENAI_DEPLOYMENT.
%
%   APIKey                  - The API key for accessing the Azure OpenAI Chat API.
%                             Needs to be specified or stored in the
%                             environment variable AZURE_OPENAI_API_KEY.
%
%   Temperature             - Temperature value for controlling the randomness
%                             of the output. Default value is 1; higher values
%                             increase the randomness (in some sense,
%                             the “creativity”) of outputs, lower values
%                             reduce it. Setting Temperature=0 removes
%                             randomness from the output altogether.
%
%   TopP                    - Top probability mass value for controlling the
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
%                             "text" (default) | "json" | struct | string with JSON Schema
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
%                             "2024-06-01" (default) | "2024-02-01" | "2024-08-01-preview" | "2024-05-01-preview" | ...
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
%       TopP                 - Top probability mass to consider for generation.
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
%       ResponseFormat       - The format of response the model returns.
%                              "text" (default) | "json" | struct | string with JSON Schema
%
%       TimeOut              - Connection Timeout in seconds.
%

% Copyright 2023-2025 The MathWorks, Inc.

    properties(SetAccess=private)
        Endpoint     (1,1) string
        DeploymentID (1,1) string
        APIVersion   (1,1) string
    end

    properties (Hidden)
        % test seam
        sendRequestFcn = @llms.internal.sendRequestWrapper
    end

    methods
        function this = azureChat(systemPrompt, nvp)
            arguments
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Endpoint                 (1,1) string {llms.utils.mustBeNonzeroLengthTextScalar}
                nvp.DeploymentID             (1,1) string {llms.utils.mustBeNonzeroLengthTextScalar}
                nvp.APIKey                         {llms.utils.mustBeNonzeroLengthTextScalar}
                nvp.Tools                    (1,:) {mustBeA(nvp.Tools, "openAIFunction")} = openAIFunction.empty
                nvp.APIVersion               (1,1) string {mustBeAPIVersion} = "2024-10-21"
                nvp.Temperature                    {llms.utils.mustBeValidTemperature} = 1
                nvp.TopP                           {llms.utils.mustBeValidProbability} = 1
                nvp.StopSequences                  {llms.utils.mustBeValidStop} = {}
                nvp.ResponseFormat                 {llms.utils.mustBeResponseFormat} = "text"
                nvp.PresencePenalty                {llms.utils.mustBeValidPenalty} = 0
                nvp.FrequencyPenalty               {llms.utils.mustBeValidPenalty} = 0
                nvp.TimeOut                  (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 10
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

            this.Endpoint = getEndpoint(nvp);
            this.DeploymentID = getDeployment(nvp);
            this.APIKey = llms.internal.getApiKeyFromNvpOrEnv(nvp,"AZURE_OPENAI_API_KEY");
            this.APIVersion = nvp.APIVersion;
            this.ResponseFormat = nvp.ResponseFormat;
            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.StopSequences = nvp.StopSequences;
            this.PresencePenalty = nvp.PresencePenalty;
            this.FrequencyPenalty = nvp.FrequencyPenalty;
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
            %       ToolChoice       - Function to execute. "none", "auto", "required",
            %                          or specify the function to call.
            %                          The default value is "auto".
            %
            %       Tools            - Array of openAIFunction objects representing
            %                          custom functions to be used during chat completions.
            %                          The default value is CHAT.Tools.
            %
            %       Seed             - An integer value to use to obtain
            %                          reproducible responses
            %
            %       Temperature      - Temperature value for controlling the randomness
            %                          of the output. The default value is CHAT.Temperature;
            %                          higher values increase the randomness (in some sense,
            %                          the “creativity”) of outputs, lower values
            %                          reduce it. Setting Temperature=0 removes
            %                          randomness from the output altogether.
            %
            %       TopP             - Top probability mass value for controlling the
            %                          diversity of the output. Default value is CHAT.TopP;
            %                          lower values imply that only the more likely
            %                          words can appear in any particular place.
            %                          This is also known as top-p sampling.
            %
            %       StopSequences    - Vector of strings that when encountered, will
            %                          stop the generation of tokens. Default
            %                          value is CHAT.StopSequences.
            %                          Example: ["The end.", "And that's all she wrote."]
            %
            %       ResponseFormat   - The format of response the call returns.
            %                          Default value is CHAT.ResponseFormat.
            %                          "text" | "json" | struct | string with JSON Schema
            %
            %       PresencePenalty  - Penalty value for using a token in the response
            %                          that has already been used. Default value is 
            %                          CHAT.PresencePenalty.
            %                          Higher values reduce repetition of words in the output.
            %
            %       FrequencyPenalty - Penalty value for using a token that is frequent
            %                          in the output. Default value is CHAT.FrequencyPenalty.
            %                          Higher values reduce repetition of words in the output.
            %
            %       StreamFun        - Function to callback when streaming the result.
            %                          Default value is CHAT.StreamFun.
            %
            %       TimeOut          - Connection Timeout in seconds. Default value is CHAT.TimeOut.
            %
            %
            % Currently, GPT-4 Turbo with vision does not support the message.name
            % parameter, functions/tools, response_format parameter, stop
            % sequences, and max_tokens

            arguments
                this                    (1,1) azureChat
                messages                {mustBeValidMsgs}
                nvp.Temperature               {llms.utils.mustBeValidTemperature} = this.Temperature
                nvp.TopP                      {llms.utils.mustBeValidProbability} = this.TopP
                nvp.StopSequences             {llms.utils.mustBeValidStop} = this.StopSequences
                nvp.ResponseFormat            {llms.utils.mustBeResponseFormat} = this.ResponseFormat
                nvp.APIKey                    {llms.utils.mustBeNonzeroLengthTextScalar} = this.APIKey
                nvp.PresencePenalty           {llms.utils.mustBeValidPenalty} = this.PresencePenalty
                nvp.FrequencyPenalty          {llms.utils.mustBeValidPenalty} = this.FrequencyPenalty
                nvp.TimeOut             (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = this.TimeOut
                nvp.StreamFun           (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
                nvp.NumCompletions      (1,1) {mustBeNumeric,mustBePositive, mustBeInteger} = 1
                nvp.MaxNumTokens        (1,1) {mustBeNumeric,mustBePositive} = inf
                nvp.ToolChoice          (1,:) {mustBeTextScalar} = "auto"
                nvp.Tools               (1,:) {mustBeA(nvp.Tools, "openAIFunction")}
                nvp.Seed                {mustBeIntegerOrEmpty(nvp.Seed)} = []
            end

            if isfield(nvp, 'Tools')
                [functionsStruct, functionNames] = functionAsStruct(nvp.Tools);
            else
                functionsStruct = this.FunctionsStruct;
                functionNames = this.FunctionNames;
            end

            mustBeValidFunctionCall(this, nvp.ToolChoice, functionNames);
            toolChoice = convertToolChoice(this, nvp.ToolChoice, functionNames);

            messages = convertCharsToStrings(messages);
            if isstring(messages) && isscalar(messages)
                messagesStruct = {struct("role", "user", "content", messages)};
            else
                messagesStruct = this.encodeImages(messages.Messages);
            end

            if ~isempty(this.SystemPrompt)
                messagesStruct = horzcat(this.SystemPrompt, messagesStruct);
            end
!
            if isfield(nvp,"StreamFun")
                streamFun = nvp.StreamFun;
            else
                streamFun = this.StreamFun;
            end

            try
                [text, message, response] = llms.internal.callAzureChatAPI(this.Endpoint, ...
                    this.DeploymentID, messagesStruct, functionsStruct, ...
                    ToolChoice=toolChoice, APIVersion = this.APIVersion, Temperature=nvp.Temperature, ...
                    TopP=nvp.TopP, NumCompletions=nvp.NumCompletions,...
                    StopSequences=nvp.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                    PresencePenalty=nvp.PresencePenalty, FrequencyPenalty=nvp.FrequencyPenalty, ...
                    ResponseFormat=nvp.ResponseFormat,Seed=nvp.Seed, ...
                    APIKey=nvp.APIKey,TimeOut=nvp.TimeOut,StreamFun=streamFun,...
                    sendRequestFcn=this.sendRequestFcn);
            catch ME
                if ismember(ME.identifier,...
                    ["MATLAB:webservices:UnknownHost","MATLAB:webservices:Timeout"])
                    % throw(ME) would still print a long stack trace, from
                    % ME.cause.stack. We cannot change ME.cause, so we
                    % throw a new error:
                    error(ME.identifier,ME.message);
                end
                throw(ME);
            end

            if isfield(response.Body.Data,"error")
                error("llms:apiReturnedError",llms.utils.errorMessageCatalog.getMessage("llms:apiReturnedError",response.Body.Data.error.message));
            end

            if ~isempty(text)
                text = llms.internal.reformatOutput(text,nvp.ResponseFormat);
            end
        end
    end

    methods(Hidden)
        function messageStruct = encodeImages(~, messageStruct)
            for k=1:numel(messageStruct)
                if isfield(messageStruct{k},"images")
                    images = messageStruct{k}.images;
                    detail = messageStruct{k}.image_detail;
                    messageStruct{k} = rmfield(messageStruct{k},["images","image_detail"]);
                    messageStruct{k}.content = ...
                        {struct("type","text","text",messageStruct{k}.content)};
                    for img = images(:).'
                        if startsWith(img,("https://"|"http://"))
                            s = struct( ...
                                "type","image_url", ...
                                "image_url",struct("url",img));
                        else
                            [~,~,ext] = fileparts(img);
                            MIMEType = "data:image/" + erase(ext,".") + ";base64,";
                            % Base64 encode the image using the given MIME type
                            fid = fopen(img);
                            im = fread(fid,'*uint8');
                            fclose(fid);
                            b64 = matlab.net.base64encode(im);
                            s = struct( ...
                                "type","image_url", ...
                                "image_url",struct("url",MIMEType + b64));
                        end

                        s.image_url.detail = detail;

                        messageStruct{k}.content{end+1} = s;
                    end
                end
            end
        end
    end
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
        mustBeNumeric(value)
        mustBeInteger(value)
    end
end

function mustBeAPIVersion(model)
    mustBeMember(model,llms.azure.apiVersions);
end

function endpoint = getEndpoint(nvp)
    if isfield(nvp, "Endpoint")
        endpoint = nvp.Endpoint;
    else
        if isenv("AZURE_OPENAI_ENDPOINT")
            endpoint = getenv("AZURE_OPENAI_ENDPOINT");
        else
            error("llms:endpointMustBeSpecified", llms.utils.errorMessageCatalog.getMessage("llms:endpointMustBeSpecified"));
        end
    end
end

function deployment = getDeployment(nvp)
    if isfield(nvp, "DeploymentID")
        deployment = nvp.DeploymentID;
    else
        if isenv("AZURE_OPENAI_DEPLOYMENT")
            deployment = getenv("AZURE_OPENAI_DEPLOYMENT");
        else
            error("llms:deploymentMustBeSpecified", llms.utils.errorMessageCatalog.getMessage("llms:deploymentMustBeSpecified"));
        end
    end
end
