
# generate

Generate image using OpenAI® image generation API


`[images,httpResponse] = generate(model,prompt)`


`___ = generate(___,Name=Value)`

# Description

`[images,httpResponse] = generate(model,prompt)` generates images from an OpenAI image generation model given a natural language prompt.


`___ = generate(___,Name=Value)` specifies additional options using one or more name\-value arguments.

# Examples
## Generate Image

First, specify the OpenAI API key as an environment variable and save it to a file called `".env"`. Next, load the environment file using the `loadenv` function.

```matlab
loadenv(".env")
```

Connect to the OpenAI Images API.

```matlab
model = openAIImages(ModelName="gpt-image-1-mini");
```

Generate an image based on a natural language prompt.

```matlab
catImage = generate(model,"An image of a cat confused by a complicated knitting pattern.");
```

# Input Arguments
### `model` — Image generation model

`openAIImages` object


Image generation model, specified as an [`openAIImages`](openAIImages.md) object.

### `prompt` — User prompt

character vector | string scalar


Natural language prompt instructing the model what to do.


**Example:** `"Please draw a frog wearing spectacles."`

## Name\-Value Arguments
### `NumImages` — Number of images to generate

`1` (default) | positive integer


Specify the number of images to generate.


### `Size` — Size of generated image

`"auto"` (default) | `1024x1024` | `1536x1024` | `1024x1536`


Size of the generated image in pixels.

If you specify `Size` as `"auto"`, the software uses the default size of the model.


### `Quality` — Quality of generated image

`"auto"` (default) | `"high"` | `"medium"` | `"low"`


Specify the OpenAI `"quality"` parameter.

If you specify `"Quality"` as `"auto"`, then the software uses the default value of the model.


# Output Argument
### `images` — Generated images

cell array of numerical matrices


Images that the model generates, returned as a cell array with `NumImages` elements. Each element of the cell array contains a generated image specified as an RGB images of size `Size`. For example, if you specify `Size="1024x1024"`, then the generated images have size `1024x1024x3`.

### `httpResponse` — HTTP response message

`matlab.net.http.ResponseMessage` object


Response message returned by the server, specified as a [`matlab.net.http.ResponseMessage`](https://www.mathworks.com/help/matlab/ref/matlab.net.http.responsemessage-class.html) object.

# See Also

[`openAIImages`](openAIImages.md) | [`edit`](edit.md)

*Copyright 2024-2026 The MathWorks, Inc.*
