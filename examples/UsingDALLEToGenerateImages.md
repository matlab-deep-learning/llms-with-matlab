
# Using DALL·E™ to generate images

To run the code shown on this page, open the MLX file in MATLAB: [mlx-scripts/UsingDALLEToGenerateImages.mlx](mlx-scripts/UsingDALLEToGenerateImages.mlx) 

This example shows how to generate images using the `openAIImages` object.


To run this example, you need a valid OpenAI™ API key. Creating images using DALL\-E may incur a fee.

```matlab
loadenv(".env")
addpath('../..') 
```
# Image Generation with DALL·E 3

Create an `openAIImages` object with `ModelName` `dall-e-3`.

```matlab
mdl = openAIImages(ModelName="dall-e-3");
```

Generate and visualize an image. This model only supports the generation of one image per request.

```matlab
images = generate(mdl,"A crispy fresh API key");
figure
imshow(images{1})
```

![figure_0.png](UsingDALLEToGenerateImages_media/figure_0.png)

You can also define the style and quality of the image

```matlab
images = generate(mdl,"A cat playing with yarn", Quality="hd", Style="natural");
figure
imshow(images{1})
```

![figure_1.png](UsingDALLEToGenerateImages_media/figure_1.png)

*Copyright 2024 The MathWorks, Inc.*

