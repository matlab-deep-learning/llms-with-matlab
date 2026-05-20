classdef openAIImages < llms.internal.needsAPIKey
%openAIImages Connect to Images API from OpenAI.
%
%   MDL = openAIImages creates an openAIImages object with gpt-image-1-mini
%
%   MDL = openAIImages(ModelName) uses the specified model
%
%       ModelName            - Name of the model to use for image generation.
%                             "gpt-image-1-mini" (default), "gpt-image-1",
%                             "gpt-image-1.5", or "gpt-image-2".
%
%   MDL = openAIImages(ModelName, APIKey=key) uses the specified API key
%
%   MDL = openAIImages(__, Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%       TimeOut              - Connection Timeout in seconds (default: 10 secs)
%
%   openAIImages Functions:
%       openAIImages         - Text to Images API from OpenAI.
%       generate             - Generate images using the openAIImages instance.
%       edit                 - Edit image from a given image and prompt.
%
%   openAIImages Properties:
%       ModelName            - Name of the model to use for image generation.
%                             "gpt-image-1-mini" (default), "gpt-image-1",
%                             "gpt-image-1.5", or "gpt-image-2"
%
%       TimeOut              - Connection Timeout in seconds (default: 10 secs)
%

% Copyright 2024-2026 The MathWorks, Inc.

    properties(SetAccess=private)
        %ModelName   Model name.
        ModelName

        %TimeOut    Connection timeout in seconds (default 10 secs)
        TimeOut
    end

    methods
        function this = openAIImages(nvp)
            arguments
                nvp.ModelName   (1,1) string {mustBeTextScalar} = "gpt-image-1-mini"
                nvp.APIKey            {llms.utils.mustBeNonzeroLengthTextScalar}
                nvp.TimeOut     (1,1) {mustBeNumeric,mustBeReal,mustBePositive} = 10
            end

            this.ModelName = nvp.ModelName;
            this.APIKey = llms.internal.getApiKeyFromNvpOrEnv(nvp,"OPENAI_API_KEY");
            this.TimeOut = nvp.TimeOut;
        end

        function [images, response] = generate(this,prompt,nvp)
            %generate Generate images using the openAIImages instance
            %
            %   [IMAGES, RESPONSE] = generate(MDL, PROMPT) generates images
            %   with the specified prompt.  The PROMPT should be a text description
            %   of the desired image(s).
            %
            %   [IMAGES, RESPONSE] = generate(__, Name=Value) specifies
            %   additional options.
            %
            %       NumImages        - Number of images to generate.
            %                          Default value is 1. The max is 10.
            %
            %       Size             - Size of the generated images.
            %                          "auto" (default), "1024x1024",
            %                          "1536x1024" (landscape), or
            %                          "1024x1536" (portrait).
            %
            %       Quality          - Quality of the images to generate.
            %                          "auto" (default), "high", "medium",
            %                          or "low".

            arguments
                this                    (1,1) openAIImages
                prompt                        {llms.utils.mustBeNonzeroLengthTextScalar}
                nvp.NumImages           (1,1) {mustBeNumeric,mustBePositive,mustBeInteger,...
                                                mustBeLessThanOrEqual(nvp.NumImages,10)} = 1
                nvp.Size                (1,1) string = "auto"
                nvp.Quality             (1,1) string {mustBeMember(nvp.Quality, ...
                                                ["auto", "high", "medium", "low"])} = "auto"
                nvp.Style
            end

            if isfield(nvp, "Style")
                error("llms:deprecatedOption", ...
                    llms.utils.errorMessageCatalog.getMessage("llms:deprecatedOption", ...
                    "Style"));
            end

            validateSize(this.ModelName, nvp.Size)

            endpoint = "https://api.openai.com/v1/images/generations";

            validatePromptSize(this.ModelName, prompt)

            params = struct("prompt",prompt,...
                "model",this.ModelName,...
                "n",nvp.NumImages,...
                "size",nvp.Size,...
                "quality",nvp.Quality);

            % Send the HTTP Request
            response = sendRequest(this, endpoint, params);

            % Output the images
            images = extractImages(response);
        end

        function [images, response] = edit(this,imagePath,prompt,nvp)
            %edit Generate an edited or extended image from a given image and prompt
            %
            %   [IMAGES, RESPONSE] = edit(MDL, IMAGEPATH, PROMPT)
            %   generates new images from an original image and prompt
            %
            %       imagePath        - The path to the source image file.
            %                          Must be a valid PNG file, less than 4MB,
            %                          and square. If mask is not provided,
            %                          image must have transparency, which
            %                          will be used as the mask.
            %
            %       prompt           - A text description of the desired image(s).
            %                          The maximum length: 32000 characters
            %
            %   [IMAGES, RESPONSE] = edit(__, Name=Value) specifies
            %   additional options.
            %
            %       MaskImagePath    - The path to the image file whose
            %                          fully transparent area indicates
            %                          where the source image should be edited.
            %                          Must be a valid PNG file, less than 4MB,
            %                          and have the same dimensions as
            %                          source image.
            %
            %       NumImages        - Number of images to generate.
            %                          Default value is 1. The max is 10.
            %
            %       Size             - Size of the generated images.
            %                          "auto" (default), "1024x1024",
            %                          "1536x1024" (landscape), or
            %                          "1024x1536" (portrait).

            arguments
                this                    (1,1)  openAIImages
                imagePath                     {mustBeValidFileType(imagePath)}
                prompt                        {llms.utils.mustBeNonzeroLengthTextScalar}
                nvp.MaskImagePath             {mustBeValidFileType(nvp.MaskImagePath)}
                nvp.NumImages           (1,1) {mustBeNumeric,mustBePositive,mustBeInteger,...
                                                mustBeLessThanOrEqual(nvp.NumImages,10)} = 1
                nvp.Size                (1,1) string = "auto"
            end

            validateSize(this.ModelName, nvp.Size)
            validatePromptSize(this.ModelName, prompt)

            endpoint = 'https://api.openai.com/v1/images/edits';

            % Required params
            numImages = num2str(nvp.NumImages);
            body = matlab.net.http.io.MultipartFormProvider( ...
                'model',matlab.net.http.io.FormProvider(this.ModelName), ...
                'image',matlab.net.http.io.FileProvider(imagePath), ...
                'prompt',matlab.net.http.io.FormProvider(prompt), ...
                'n',matlab.net.http.io.FormProvider(numImages),...
                'size',matlab.net.http.io.FormProvider(nvp.Size));

            % Optional param
            if isfield(nvp,"MaskImagePath")
                body.Names = [body.Names,"mask"];
                body.Parts = [body.Parts,{matlab.net.http.io.FileProvider(nvp.MaskImagePath)}];
            end

            % Send the HTTP Request
            response = sendRequest(this, endpoint, body);
            % Output the images
            images = extractImages(response);
        end

        function response = sendRequest(this, endpoint, body)
        %sendRequest send request to the given endpoint, return response
            headers =  matlab.net.http.HeaderField('Authorization', "Bearer " + this.APIKey);
            if isa(body,'struct')
                headers(2) =  matlab.net.http.HeaderField('Content-Type', 'application/json');
            end
            request =  matlab.net.http.RequestMessage('post', headers, body);

            httpOpts = matlab.net.http.HTTPOptions;
            httpOpts.ConnectTimeout = this.TimeOut;
            response = send(request, matlab.net.URI(endpoint), httpOpts);
        end
    end

    methods(Hidden)
        function [images, response] = createVariation(~, varargin) %#ok<VANUS>
            error("llms:deprecatedMethod", ...
                llms.utils.errorMessageCatalog.getMessage("llms:deprecatedMethod", ...
                "createVariation"));
        end
    end
end

function images = extractImages(response)

if response.StatusCode=="OK" && isfield(response.Body.Data.data, "b64_json")
    b64data = arrayfun(@(x) string(x.b64_json), response.Body.Data.data);
    images = cellfun(@b64ToImage, num2cell(b64data), UniformOutput=false);
else
    images = [];
end
end

function validateSize(model, sz)
if ismember(model, ["gpt-image-1", "gpt-image-1-mini", "gpt-image-1.5"])
    mustBeMember(sz, ["auto", "1024x1024", "1536x1024", "1024x1536"])
end
end

function validatePromptSize(model, prompt)
numChars = numel(char(prompt));
limit = 32000;
if numChars>limit
    error("llms:promptLimitCharacter", ...
        llms.utils.errorMessageCatalog.getMessage("llms:promptLimitCharacter", ...
        string(limit), model));
end
end

function mustBeValidFileType(filePath)
    mustBeFile(filePath);
    s = dir(filePath);
    imgDetails = imfinfo(filePath);
    imgFormat = imgDetails.Format;
    if ~(imgFormat=="png")
        error("llms:pngExpected", ...
            llms.utils.errorMessageCatalog.getMessage("llms:pngExpected"));
    end
    mustBeLessThan(s.bytes,4e+6)
end

function data = b64ToImage(b64str)
    bytes = matlab.net.base64decode(b64str);
    filename = tempname + ".png";
    clean = onCleanup(@() delete(filename));
    fid = fopen(filename, 'w');
    fwrite(fid, bytes);
    fclose(fid);
    data = imread(filename);
end
