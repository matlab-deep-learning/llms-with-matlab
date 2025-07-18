classdef (Sealed) ollamaChat < llms.internal.textGenerator & ...
    llms.internal.hasTools 
%ollamaChat Chat completion API from Ollama™.
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
%                             Higher values increase the randomness (in some
%                             sense, the “creativity”) of outputs, lower
%                             values reduce it. Setting Temperature=0 removes
%                             randomness from the output altogether.
%
%   TopP                    - Top probability mass value for controlling the
%                             diversity of the output. Default value is 1;
%                             lower values imply that only the more likely
%                             words can appear in any particular place.
%                             This is also known as top-p sampling.
%
%   MinP                    - Minimum probability ratio for controlling the
%                             diversity of the output. Default value is 0;
%                             higher values imply that only the more likely
%                             words can appear in any particular place.
%                             This is also known as min-p sampling.
%
%   TopK                    - Maximum number of most likely tokens that are
%                             considered for output. Default is Inf, allowing
%                             all tokens. Smaller values reduce diversity in
%                             the output.
%
%   TailFreeSamplingZ       - Reduce the use of less probable tokens, based on
%                             the second-order differences of ordered
%                             probabilities. Default value is 1, disabling
%                             tail-free sampling. Lower values reduce
%                             diversity, with some authors recommending
%                             values around 0.95. Tail-free sampling is
%                             slower than using TopP or TopK.
%
%   StopSequences           - Vector of strings that when encountered, will
%                             stop the generation of tokens. Default
%                             value is empty.
%                             Example: ["The end.", "And that's all she wrote."]
%
%   ResponseFormat          - The format of response the model returns.
%                             "text" (default) | "json"
%
%   StreamFun               - Function to callback when streaming the
%                             result.
%
%   TimeOut                 - Connection Timeout in seconds. Default is 120.
%
%   Tools                   - A list of tools the model can call.
%
%
%   ollamaChat Functions:
%       ollamaChat           - Chat completion API using Ollama server.
%       generate             - Generate a response using the ollamaChat instance.
%
%   ollamaChat Properties, in addition to the name-value pairs above:
%       ModelName            - Model name (as expected by Ollama server).
%
%       SystemPrompt         - System prompt.

% Copyright 2024-2025 The MathWorks, Inc.

    properties
        ModelName         (1,1) string
        Endpoint          (1,1) string
        TopK              (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = Inf
        MinP              (1,1) {llms.utils.mustBeValidProbability} = 0
        TailFreeSamplingZ (1,1) {mustBeNumeric,mustBeReal} = 1
    end

    properties (Hidden)
        % test seam
        sendRequestFcn = @llms.internal.sendRequestWrapper
    end

    methods
        function this = ollamaChat(modelName, systemPrompt, nvp)
            arguments
                modelName                          {mustBeTextScalar}
                systemPrompt                       {llms.utils.mustBeTextOrEmpty} = []
                nvp.Temperature                    {llms.utils.mustBeValidTemperature} = 1
                nvp.Tools                    (1,:) {mustBeA(nvp.Tools, "openAIFunction")} = openAIFunction.empty
                nvp.TopP                           {llms.utils.mustBeValidProbability} = 1
                nvp.MinP                           {llms.utils.mustBeValidProbability} = 0
                nvp.TopK                     (1,1) {mustBeReal,mustBePositive} = Inf
                nvp.StopSequences                  {llms.utils.mustBeValidStop} = {}
                nvp.ResponseFormat                 {llms.utils.mustBeResponseFormat} = "text"
                nvp.TimeOut                  (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 120
                nvp.TailFreeSamplingZ        (1,1) {mustBeNumeric,mustBeReal} = 1
                nvp.StreamFun                (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
                nvp.Endpoint                 (1,1) string = "127.0.0.1:11434"
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

            this.ModelName = modelName;
            this.ResponseFormat = nvp.ResponseFormat;
            this.Temperature = nvp.Temperature;
            this.TopP = nvp.TopP;
            this.MinP = nvp.MinP;
            this.TopK = nvp.TopK;
            this.TailFreeSamplingZ = nvp.TailFreeSamplingZ;
            this.StopSequences = nvp.StopSequences;
            this.TimeOut = nvp.TimeOut;
            this.Endpoint = nvp.Endpoint;
        end

        function [text, message, response] = generate(this, messages, nvp)
            %generate   Generate a response using the ollamaChat instance.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(CHAT, MESSAGES) generates a response
            %   with the specified MESSAGES.
            %
            %   [TEXT, MESSAGE, RESPONSE] = generate(__, Name=Value) specifies additional options
            %   using one or more name-value arguments:
            %
            %       MaxNumTokens      - Maximum number of tokens in the generated response.
            %                           Default value is inf.
            %
            %       Seed              - An integer value to use to obtain
            %                           reproducible responses
            %
            %       ModelName         - Model name (as expected by Ollama server).
            %                           Default value is CHAT.ModelName.
            %
            %       Temperature       - Temperature value for controlling the randomness
            %                           of the output. Default value is CHAT.Temperature.
            %                           Higher values increase the randomness (in some
            %                           sense, the “creativity”) of outputs, lower
            %                           values reduce it. Setting Temperature=0 removes
            %                           randomness from the output altogether.
            %
            %       ToolChoice       - Function to execute. 'none', 'auto',
            %                          or specify the function to call.
            %
            %       TopP              - Top probability mass value for controlling the
            %                           diversity of the output. Default value is CHAT.TopP;
            %                           lower values imply that only the more likely
            %                           words can appear in any particular place.
            %                           This is also known as top-p sampling.
            %
            %       MinP              - Minimum probability ratio for controlling the
            %                           diversity of the output. Default value is CHAT.MinP;
            %                           higher values imply that only the more likely
            %                           words can appear in any particular place.
            %                           This is also known as min-p sampling.
            %
            %       TopK              - Maximum number of most likely tokens that are
            %                           considered for output. Default is CHAT.TopK.
            %                           Smaller values reduce diversity in the output.
            %
            %       TailFreeSamplingZ - Reduce the use of less probable tokens, based on
            %                           the second-order differences of ordered
            %                           probabilities.
            %                           Default value is CHAT.TailFreeSamplingZ.
            %                           Lower values reduce diversity, with
            %                           some authors recommending values
            %                           around 0.95. Tail-free sampling is
            %                           slower than using TopP or TopK.
            %
            %       StopSequences     - Vector of strings that when encountered, will
            %                           stop the generation of tokens. Default
            %                           value is CHAT.StopSequences.
            %                           Example: ["The end.", "And that's all she wrote."]
            %
            %       ResponseFormat   - The format of response the call returns.
            %                          Default value is CHAT.ResponseFormat.
            %                          "text" | "json" | struct | string with JSON Schema
            %
            %       StreamFun         - Function to callback when streaming the
            %                           result. The default value is CHAT.StreamFun.
            %
            %       TimeOut           - Connection Timeout in seconds. Default is CHAT.TimeOut.
            %

            arguments
                this                    (1,1) ollamaChat
                messages                      {mustBeValidMsgs}
                nvp.ModelName                 {mustBeTextScalar} = this.ModelName
                nvp.Temperature               {llms.utils.mustBeValidTemperature} = this.Temperature
                nvp.TopP                      {llms.utils.mustBeValidProbability} = this.TopP
                nvp.MinP                      {llms.utils.mustBeValidProbability} = this.MinP
                nvp.TopK                (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = this.TopK
                nvp.StopSequences             {llms.utils.mustBeValidStop} = this.StopSequences
                nvp.ResponseFormat            {llms.utils.mustBeResponseFormat} = this.ResponseFormat
                nvp.TimeOut             (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = this.TimeOut
                nvp.TailFreeSamplingZ   (1,1) {mustBeNumeric,mustBeReal} = this.TailFreeSamplingZ
                nvp.StreamFun           (1,1) {mustBeA(nvp.StreamFun,'function_handle')}
                nvp.Endpoint            (1,1) string = this.Endpoint
                nvp.MaxNumTokens        (1,1) {mustBeNumeric,mustBePositive} = inf
                nvp.ToolChoice          {mustBeValidFunctionCall(this, nvp.ToolChoice)} = []
                nvp.Seed                      {mustBeIntegerOrEmpty(nvp.Seed)} = []
            end

            messages = convertCharsToStrings(messages);
            if isstring(messages) && isscalar(messages)
                messagesStruct = {struct("role", "user", "content", messages)};
            else
                messagesStruct = this.encodeImages(messages.Messages);
            end

            if ~isempty(this.SystemPrompt)
                messagesStruct = horzcat(this.SystemPrompt, messagesStruct);
            end

            toolChoice = convertToolChoice(this, nvp.ToolChoice);

            if isfield(nvp,"StreamFun")
                streamFun = nvp.StreamFun;
            else
                streamFun = this.StreamFun;
            end

            try
                [text, message, response] = llms.internal.callOllamaChatAPI(...
                    nvp.ModelName, messagesStruct, this.FunctionsStruct, ...
                    Temperature=nvp.Temperature, ToolChoice=toolChoice, ...
                    TopP=nvp.TopP, MinP=nvp.MinP, TopK=nvp.TopK,...
                    TailFreeSamplingZ=nvp.TailFreeSamplingZ,...
                    StopSequences=nvp.StopSequences, MaxNumTokens=nvp.MaxNumTokens, ...
                    ResponseFormat=nvp.ResponseFormat,Seed=nvp.Seed, ...
                    TimeOut=nvp.TimeOut, StreamFun=streamFun, ...
                    Endpoint=nvp.Endpoint, sendRequestFcn=this.sendRequestFcn);
            catch e
                if e.identifier == "MATLAB:webservices:ConnectionRefused"
                    error("llms:noOllamaFound",llms.utils.errorMessageCatalog.getMessage("llms:noOllamaFound",nvp.Endpoint));
                end
                % for nicer errors, throw instead of rethrow, reducing the stack depth shown
                throw(e);
            end 

            if isfield(response.Body.Data,"error")
                [versionStr, versionList] = serverVersion(nvp.Endpoint);
                if llms.utils.requestsStructuredOutput(nvp.ResponseFormat) && ...
                    ~versionIsAtLeast(versionList, [0,5,0])
                    error("llms:OllamaStructuredOutputNeeds05",llms.utils.errorMessageCatalog.getMessage("llms:OllamaStructuredOutputNeeds05", versionStr));
                end
                err = response.Body.Data.error;
                error("llms:apiReturnedError",llms.utils.errorMessageCatalog.getMessage("llms:apiReturnedError",err));
            end

            text = llms.internal.reformatOutput(text,nvp.ResponseFormat);
        end
    end

    methods (Access=private)
        function messageStruct = encodeImages(~, messageStruct)
            for k=1:numel(messageStruct)
                if isfield(messageStruct{k},"images")
                    images = messageStruct{k}.images;
                    % detail = messageStruct{k}.image_detail;
                    messageStruct{k} = rmfield(messageStruct{k},["images","image_detail"]);
                    imgs = cell(size(images));
                    for n = 1:numel(images)
                        img = images(n);
                        % Base64 encode the image
                        fid = fopen(img);
                        im = fread(fid,'*uint8');
                        fclose(fid);
                        imgs{n} = matlab.net.base64encode(im);
                    end
                    messageStruct{k}.images = imgs;
                end
            end
        end
    end

    methods(Static)
        function mdls = models
            %ollamaChat.models - return models available on Ollama server
            %   MDLS = ollamaChat.models returns a string vector MDLS
            %   listing the models available on the local Ollama server.
            %
            %   These names can be used in the ollamaChat constructor.
            %   For names with a colon, such as "phi:latest", it is
            %   possible to only use the part before the colon, i.e.,
            %   "phi".
            endpoint = "http://localhost:11434/api/tags";
            response = webread(endpoint);
            mdls = string({response.models.name}).';
            baseMdls = unique(extractBefore(mdls,":latest"));
            % remove all those "mistral:latest", iff those are the only
            % model entries pointing at some model
            for base=baseMdls.'
                found = startsWith(mdls,base+":");
                if nnz(found) == 1
                    mdls(found) = [];
                end
            end
            mdls = unique([mdls(:); baseMdls]);
            mdls(strlength(mdls) < 1) = [];
            mdls(ismissing(mdls)) = [];
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

function [versionStr, versionList] = serverVersion(endpoint)
    URL = endpoint + "/api/version";
    if ~startsWith(URL,"http")
        URL = "http://" + URL;
    end
    versionStr = webread(URL).version;
    versionList = split(versionStr,'.');
    versionList = str2double(versionList);
end

function tf = versionIsAtLeast(version,minVersion)
    tf = version(1) > minVersion(1) || ...
        (version(1) == minVersion(1) && (...
            version(2) > minVersion(2) || ...
            (version(2) == minVersion(2) && version(3) >= minVersion(3))));
end
