
# Describe Images Using ChatGPT™

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/DescribeImagesUsingChatGPT.mlx](mlx-scripts/DescribeImagesUsingChatGPT.mlx) 

This example shows how to generate image descriptions using the addUserMessageWithImages function. To run this example, you need a valid API key from a paid OpenAI™ API account, and a history of successful payment.

```matlab
loadenv(".env")
addpath('../..')
```
# Load and Display Image Data

Load the sample image from Wikipedia. Use the `imread` function to read images from URLs or filenames.

```matlab
image_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg';
im = imread(image_url);
imshow(im)
```

![figure_0.png](DescribeImagesUsingChatGPT_media/figure_0.png)
# Generate Image Descriptions

Ask questions about the image with the URL.

```matlab
chat = openAIChat("You are an AI assistant."); 
```

Create a message and pass the image URL along with the prompt.

```matlab
messages = messageHistory;
messages = addUserMessageWithImages(messages,"What is in the image?", string(image_url));
```

Generate a response. By default, the model returns a very short response. To override it, set `MaxNumTokens` to 4096. 

```matlab
[txt,~,response] = generate(chat,messages,MaxNumTokens=4096);
if response.StatusCode == "OK"
    wrappedText = wrapText(txt)
else
    response.Body.Data.error
end
```

```matlabTextOutput
wrappedText = 
    "The image depicts a serene landscape featuring a wooden pathway that runs 
     through a lush, green marsh or meadow. The path is bordered by tall grass and 
     some shrubs, with a clear blue sky overhead dotted with clouds. The scene 
     evokes a sense of tranquility and natural beauty."

```
# Helper function
```matlab
function wrappedText = wrapText(text)
    s = textwrap(text,80);
    wrappedText = string(join(s,newline));
end
```

*Copyright 2024 The MathWorks, Inc.*

