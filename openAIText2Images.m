classdef openAIText2Images
%openAIText2Images Chat to Images API from OpenAI.
%
%   DALLE = openAIText2Images creates an openAIText2Images object with dall-e-2
%
%   DALLE = openAIText2Images(ModelName) uses the specified model
%
%       ModelName            - Name of the model to use for image generation.
%                             "dall-e-2" (default) or "dall-e-3"
%
%   DALLE = openAIText2Images(ModelName, ApiKey=key) uses the specified API key
%
%   DALLE = openAIText2Images(__, Name=Value) specifies additional options
%   using one or more name-value arguments:
%
%       TimeOut              - Connection Timeout in seconds (default: 10 secs)
%
%   openAIText2Images Functions:
%       openAIText2Images    - Text to Images API from OpenAI.
%       generateImages       - Generate images using the openAIText2Images instance.
%       editImage            - Generate an edited or extended image from
%                              a given image and prompt
%       varyImage            - Generate variations of a given image
%
%   openAIText2Images Properties:
%       ModelName            - Name of the model to use for image generation.
%                             "dall-e-2" (default) or "dall-e-3"
%
%       TimeOut              - Connection Timeout in seconds (default: 10 secs)
%
    properties(SetAccess=private)  
        ModelName
    end

    properties
        TimeOut
    end

    properties (Access=private)
        ApiKey
    end

    methods

        function this = openAIText2Images(ModelName,nvp)
            arguments
                ModelName                    (1,1) {mustBeMember(ModelName,["dall-e-2", "dall-e-3"])} = "dall-e-2"
                nvp.ApiKey                         {mustBeNonzeroLengthTextScalar} 
                nvp.TimeOut                  (1,1) {mustBeInteger,mustBePositive}
            end

            this.ModelName = ModelName;
            this.ApiKey = llms.internal.getApiKeyFromNvpOrEnv(nvp);
            if isfield(nvp,'TimeOut')
                this.TimeOut = nvp.TimeOut;
            end
        end

        function [images, response] = generateImages(this,Prompt,nvp)
            %generateImages Generate images using the openAIText2Images instance
            % 
            %   [IMAGES, RESPONSE] = generateImages(DALLE, PROMPT) generates images
            %   with the specified prompt. 
            %
            %       Prompt           - A text description of the desired image(s). 
            %                          The maximum length: 
            %                          'dall-e-2' 1000 characters 
            %                          'dall-e-3' 4000 characters.
            %
            %   [IMAGES, RESPONSE] = generateImages(__, Name=Value) specifies
            %   additiona options.
            %       
            %       NumImages        - Number of images to generate. 
            %                          Default value is 1. 
            %                          For "dall-e-3" only 1 output is supported. 
            %
            %       ResponseFormat   - How the generated images are returned. 
            %                          "url" (default). b64_json is not
            %                          supported
            %
            %       Size             - Size of the generated images. 
            %                          Defaults to 1024x1024
            %                          "dall-e-2" supports 256x256, 
            %                          512x512, or 1024x1024.
            %                          "dall-e-3" supports 1024x1024, 
            %                          1792x1024, or 1024x1792
            %
            %       Quality          - Quality of the images to generate. 
            %                          "standard" (default) or 'hd'. 
            %                          Only "dall-e-3" supports this parameter.
            %
            %       Style            - The style of the generated images. 
            %                          "vivid" (default) or "natural". 
            %                          Only "dall-e-3" supports this parameter.

            arguments
                this                    (1,1) openAIText2Images
                Prompt                  (1,1) {mustBeTextScalar}
                nvp.NumImages           (1,1) {mustBePositive, mustBeInteger} = 1
                nvp.ResponseFormat      (1,1) {mustBeMember(nvp.ResponseFormat,"url")} = "url"
                nvp.Size                (1,1) {mustBeValidSize(this,nvp.Size)} = "1024x1024"
                % dall-e-3 only
                nvp.Quality             (1,1) {mustBeMember(nvp.Quality,["standard", "hd"])} = "standard"
                nvp.Style               (1,1) {mustBeMember(nvp.Style,["vivid", "natural"])} = "vivid"
            end

            endpoint = 'https://api.openai.com/v1/images/generations';
            
            % Required params
            params = {'prompt',Prompt,'model',this.ModelName};

            % Optional params
            if isfield(nvp,"NumImages") && nvp.NumImages > 1
                numImages = num2str(nvp.NumImages);
                params = [params,{'n',numImages}];
            end
            if isfield(nvp,"Size") && ~strcmp(nvp.Size,"1024x1024")
                params = [params,{'size',nvp.Size}];
            end

            % dall-e-3 only params
            if strcmp(this.ModelName,"dall-e-3")
                if isfield(nvp,"Quality") && strcmp(nvp.Quality,"hd")
                    params = [params,{'quality',nvp.Quality}];
                end
                if isfield(nvp,"Style") && strcmp(nvp.Style,"natural")
                    params = [params,{'style',nvp.Style}];
                end
            end
            body = struct(params{:});
            
            % Send the HTTP Request
            response = sendRequest(this, endpoint, body);
   
            % Output the images
            images = openAIText2Images.extractImages(response);
        end

        function [images, response] = editImage(this,ImagePath,Prompt,nvp)
            %editImage Generate an edited or extended image from a given image and prompt
            % 
            %   [IMAGES, RESPONSE] = editImage(DALLE, IMAGEPATH, PROMPT) 
            %   generates new images from an original image and prompt
            %
            %       ImagePath        - The path to the source image file. 
            %                          Must be a valid PNG file, less than 4MB, 
            %                          and square. If mask is not provided, 
            %                          image must have transparency, which 
            %                          will be used as the mask.
            %
            %       Prompt           - A text description of the desired image(s). 
            %                          The maximum length: 1000 characters
            %
            %   [IMAGES, RESPONSE] = editImage(__, Name=Value) specifies
            %   additiona options.
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
            %       ResponseFormat   - How the generated images are returned. 
            %                          "url" (default). b64_json is not
            %                          supported
            %
            %       Size             - Size of the generated images. 
            %                          Must be one of 256x256, 512x512, or 
            %                          1024x1024 (default)

            arguments
                this                    (1,1) openAIText2Images
                ImagePath               (1,1) {mustBeValidFileType(ImagePath)}
                Prompt                  (1,1) {mustBeTextScalar}
                nvp.MaskImagePath       (1,1) {mustBeValidFileType(nvp.MaskImagePath)}
                nvp.NumImages           (1,1) {mustBePositive, mustBeInteger} = 1
                nvp.ResponseFormat      (1,1) {mustBeMember(nvp.ResponseFormat,"url")} = "url"
                nvp.Size                (1,1) {mustBeMember(nvp.Size,["256x256", "512x512","1024x1024"])} = "1024x1024"
            end

            endpoint = 'https://api.openai.com/v1/images/edits'; 

            % Required params
            import matlab.net.http.io.* 
            body = MultipartFormProvider( ...
                'image',FileProvider(ImagePath), ...
                'prompt',FormProvider(Prompt));
            % Optional params
            if isfield(nvp,"MaskImagePath")
                body.Names = [body.Names,"mask"];
                body.Parts = [body.Parts,{FileProvider(nvp.MaskImagePath)}];
            end
            if isfield(nvp,"NumImages") && nvp.NumImages > 1
                body.Names = [body.Names,"n"];
                numImages = num2str(nvp.NumImages);
                body.Parts = [body.Parts,{FormProvider(numImages)}];
            end
            if isfield(nvp,"Size") && ~strcmp(nvp.Size,"1024x1024")
                body.Names = [body.Names,"size"];
                body.Parts = [body.Parts,{FormProvider(nvp.Size)}];
            end

            % Send the HTTP Request
            response = sendRequest(this, endpoint, body);
            % Output the images
            images = openAIText2Images.extractImages(response);
        end

        function [images, response] = varyImage(this,ImagePath,nvp)
            %varyImages Generate variations from a given image
            % 
            %   [IMAGES, RESPONSE] = varyImage(DALLE, IMAGEPATH) generates new images
            %   from an original image
            %
            %       ImagePath        - The path to the source image file. 
            %                          Must be a valid PNG file, less than 4MB, 
            %                          and square.
            %
            %   [IMAGES, RESPONSE] = varyImage(__, Name=Value) specifies
            %   additiona options.
            %       
            %       NumImages        - Number of images to generate.  
            %                          Default value is 1. The max is 10. 
            %
            %       ResponseFormat   - How the generated images are returned. 
            %                          "url" (default). b64_json is not
            %                          supported
            %
            %       Size             - Size of the generated images. 
            %                          Must be one of 256x256, 512x512, or 
            %                          1024x1024 (default)

            arguments
                this                    (1,1) openAIText2Images
                ImagePath               (1,1) {mustBeValidFileType(ImagePath)}
                nvp.NumImages           (1,1) {mustBePositive, mustBeInteger} = 1
                nvp.ResponseFormat      (1,1) {mustBeMember(nvp.ResponseFormat,"url")} = "url"
                nvp.Size                (1,1) {mustBeMember(nvp.Size,["256x256", "512x512","1024x1024"])} = "1024x1024"
            end

            endpoint = 'https://api.openai.com/v1/images/variations';

            % Required params
            import matlab.net.http.io.* 
            body = MultipartFormProvider('image',FileProvider(ImagePath));
            % Optional params
            if isfield(nvp,"NumImages") && nvp.NumImages > 1
                body.Names = [body.Names,"n"];
                numImages = num2str(nvp.NumImages);
                body.Parts = [body.Parts,{FormProvider(numImages)}];
            end
            if isfield(nvp,"Size") && ~strcmp(nvp.Size,"1024x1024")
                body.Names = [body.Names,"size"];
                body.Parts = [body.Parts,{FormProvider(nvp.Size)}];
            end

            % Send the HTTP Request
            response = sendRequest(this, endpoint, body);
            % Output the images
            images = openAIText2Images.extractImages(response);
        end

        function response = sendRequest(this, endpoint, body)
        % getResponse get the response from the given endpoint
            import matlab.net.*
            import matlab.net.http.*

            if isa(body,'struct')
                headers = HeaderField('Content-Type', 'application/json');
                headers(2) = HeaderField('Authorization', "Bearer " + this.ApiKey);
            else
                headers = HeaderField('Authorization', "Bearer " + this.ApiKey);
            end
            request = RequestMessage('post', headers, body);

            if ~isempty(this.TimeOut) && this.TimeOut > 10
                % Create a HTTPOptions object;
                httpOpts = matlab.net.http.HTTPOptions;
                httpOpts.ConnectTimeout = this.TimeOut;
                response = send(request, URI(endpoint), httpOpts);
            else
                response = send(request, URI(endpoint));
            end
        end

    end

    methods(Hidden)
        % Argument Validation Functions
        function mustBeValidSize(this, imagesize)
            if strcmp(this.ModelName,"dall-e-2")
                mustBeMember(imagesize,["256x256", "512x512","1024x1024"]);
            else
                mustBeMember(imagesize,["1024x1024","1792x1024","1024x1792"])
            end
        end
    end

    methods (Static)

        function images = extractImages(response)
        %extractImages Extract images from a give reponse object
            import matlab.net.*
            if response.StatusCode=="OK"
                % Output the images
                if isfield(response.Body.Data.data,"url")
                    urls = arrayfun(@(x) string(x.url), response.Body.Data.data);
                    images = cell(1,numel(urls));
                    for ii = 1:numel(urls)
                        images{ii} = imread(urls(ii));
                    end
                else
                    images = [];
                end

            else
                images = [];
            end
        end

    end
end

function mustBeValidFileType(filePath)
    mustBeFile(filePath);
    s = dir(filePath);
    mustBeMember(endsWith(s.name,".png"),true)
    mustBeLessThan(s.bytes,4e+6)
end