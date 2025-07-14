classdef(Sealed) openAIChat < llms.internal.textGenerator & ...
    llms.internal.gptPenalties & llms.internal.hasTools & llms.internal.needsAPIKey
%openAIChat Chat completion API from OpenAI.
%
%   CHAT = openAIChat(systemPrompt) creates an openAIChat object with the
%   specified system prompt.
%
%   CHAT = openAIChat(systemPrompt,APIKey=key) uses the specified API key
%
%   CHAT = openAIChat(systemPrompt,Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%   ModelName               - Name of the model to use for chat completions.
%                             The default value is "gpt-4o-mini".
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
%   Tools                   - Array of openAIFunction objects representing
%                             custom functions to be used during chat completions.
%
%   StopSequences           - Vector of strings that when encountered, will
%                             stop the generation of tokens. Default
%                             value is empty.
%                             Example: ["The end.", "And that's all she wrote."]
%
%   PresencePenalty         - Penalty value for using a token in the response
%                             that has already been used. Default value is 0.
%                             Higher values reduce repetition of words in the output.
%
%   FrequencyPenalty        - Penalty value for using a token that is frequent
%                             in the output. Default value is 0.
%                             Higher values reduce repetition of words in the output.
%
%   TimeOut                 - Connection Timeout in seconds. Default value is 10.
%
%   StreamFun               - Function to callback when streaming the
%                             result
%
%   ResponseFormat          - The format of response the model returns.
%                             "text" (default) | "json" | struct | string with JSON Schema
%
%   openAIChat Functions:
%       openAIChat           - Chat completion API from OpenAI.
%       generate             - Generate a response using the openAIChat instance.
%
%   openAIChat Properties:
%       ModelName            - Model name.
%
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
%       ResponseFormat      - The format of response the model returns.
%                              "text" | "json" | struct | string with JSON Schema
%
%       TimeOut              - Connection Timeout in seconds.
%

% Copyright 2023-2025 The MathWorks, Inc.

    properties(SetAccess=private)
        %MODELNAME   Model name.
        ModelName
    end

    properties (Hidden)
        % test seam
        sendRequestFcn = @llms.internal.sendRequestWrapper
    end

    methods
        function this = openAIChat(systemPrompt, nvp)
            arguments
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Tools                    (1,:) {mustBeA(nvp.Tools, "openAIFunction")} = openAIFunction.empty
                nvp.ModelName                (1,1) string {mustBeModel} = "gpt-4o-mini"
                nvp.Temperature                    {llms.utils.mustBeValidTemperature} = 1
                nvp.TopP                           {llms.utils.mustBeValidProbability} = 1
                nvp.StopSequences                  {llms.utils.mustBeValidStop} = {}
                nvp.ResponseFormat                 {llms.utils.mustBeResponseFormat} = "text"
                nvp.APIKey                         {llms.utils.mustBeNonzeroLengthTextScalar}
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
                if systemPrompt ~= ""
                   this.SystemPrompt = {struct("role", "system", "content", systemPrompt)};
                end
            end

            this.ModelName = nvp.ModelName;
            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.StopSequences = nvp.StopSequences;

            % ResponseFormat is only supported in the latest models only
            llms.openai.validateResponseFormat(nvp.ResponseFormat, this.ModelName);
            this.ResponseFormat = nvp.ResponseFormat;

            this.PresencePenalty = nvp.PresencePenalty;
            this.FrequencyPenalty = nvp.FrequencyPenalty;
            this.APIKey = llms.internal.getApiKeyFromNvpOrEnv(nvp,"OPENAI_API_KEY");
            this.TimeOut = nvp.TimeOut;
        end

        function [text, message, response] = generate(this, messages, nvp)
            %generate   Generate a response using the openAIChat instance.
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
            %       ModelName        - Name of the model to use for chat completions.
            %                          The default value is CHAT.ModelName.
            %
            %       Temperature      - Temperature value for controlling the randomness
            %                          of the output. Default value is CHAT.Temperatur;
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
            %       PresencePenalty  - Penalty value for using a token in the response
            %                          that has already been used. Default value is
            %                          CHAT.PresencePenalty. Higher values reduce repetition
            %                          of words in the output.
            %
            %       FrequencyPenalty - Penalty value for using a token that is frequent
            %                          in the output. Default value is CHAT.FrequencyPenalty.
            %                          Higher values reduce repetition of words in the output.
            %
            %       TimeOut          - Connection Timeout in seconds.
            %                          Default value is CHAT.TimeOut.
            %
            %       StreamFun        - Function to callback when streaming the
            %                          result. Default value is CHAT.StreamFun.
            %
            %       ResponseFormat   - The format of response the call returns.
            %                          Default value is CHAT.ResponseFormat.
            %                          "text" | "json" | struct | string with JSON Schema
            %
            % Currently, GPT-4 Turbo with vision does not support the message.name
            % parameter, functions/tools, response_format parameter, and stop
            % sequences. It also has a low MaxNumTokens default, which can be overridden.

            arguments
                this                    (1,1) openAIChat
                messages                      {mustBeValidMsgs}
                nvp.ModelName           (1,1) string {mustBeModel} = this.ModelName
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
                nvp.ToolChoice                {mustBeValidFunctionCall(this, nvp.ToolChoice)} = []
                nvp.Seed                      {mustBeIntegerOrEmpty(nvp.Seed)} = []
            end

            toolChoice = convertToolChoice(this, nvp.ToolChoice);

            messages = convertCharsToStrings(messages);
            if isstring(messages) && isscalar(messages)
                messagesStruct = {struct("role", "user", "content", messages)};
            else
                messagesStruct = this.encodeImages(messages.Messages);
            end

            llms.openai.validateMessageSupported(messagesStruct{end}, nvp.ModelName);
            if ~isempty(this.SystemPrompt)
                messagesStruct = horzcat(this.SystemPrompt, messagesStruct);
            end

            llms.openai.validateResponseFormat(nvp.ResponseFormat, nvp.ModelName, messagesStruct);

            if isfield(nvp,"StreamFun")
                streamFun = nvp.StreamFun;
            else
                streamFun = this.StreamFun;
            end

            try % just for nicer errors, reducing the stack depth shown
                [text, message, response] = llms.internal.callOpenAIChatAPI(messagesStruct, this.FunctionsStruct,...
                    ModelName=nvp.ModelName, ToolChoice=toolChoice, Temperature=nvp.Temperature, ...
                    TopP=nvp.TopP, NumCompletions=nvp.NumCompletions,...
                    StopSequences=nvp.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                    PresencePenalty=nvp.PresencePenalty, FrequencyPenalty=nvp.FrequencyPenalty, ...
                    ResponseFormat=nvp.ResponseFormat,Seed=nvp.Seed, ...
                    APIKey=nvp.APIKey,TimeOut=nvp.TimeOut, StreamFun=streamFun, ...
                    sendRequestFcn=this.sendRequestFcn);
            catch e
                throw(e);
            end

            if isfield(response.Body.Data,"error")
                err = response.Body.Data.error.message;
                error("llms:apiReturnedError",llms.utils.errorMessageCatalog.getMessage("llms:apiReturnedError",err));
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
        'function',encodeStruct(functions(i)));
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

function mustBeModel(model)
    mustBeMember(model,llms.openai.models);
end
