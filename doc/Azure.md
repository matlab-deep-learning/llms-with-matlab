
# Azure

Connect to [Azure® OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/) from MATLAB®.

1. [Setup](#setup)
2. [Get Started](#get-started)
3. [Manage Chat History](#manage-chat-history)
4. [Images](#images)
5. [JSON\-Formatted and Structured Output](#json-formatted-and-structured-output)
   - [JSON Mode](#json-mode)
   - [Structured Output](#structured-output)
6. [Tool Calling](#tool-calling)
7. [See Also](#see-also)
8. [Examples](#examples)

<a id="setup"></a>
# Setup

First, create an Azure OpenAI Service resource and use it to deploy an LLM. To do this, follow the instructions on [https://learn.microsoft.com/en\-us/azure/ai\-services/openai/how\-to/create\-resource](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource).


To connect to Azure OpenAI Service from MATLAB using LLMs with MATLAB, specify the endpoint, deployment, and API keys associated with your resource as environment variables and save them to a file called ".env".

-  `"AZURE_OPENAI_ENDPOINT"` — Network address of the server hosting the deployed model. 
-  `"AZURE_OPENAI_DEPLOYMENT"` — Name of the deployed model. 
-  `"AZURE_OPENAI_API_KEY"` — API key. You can use either `KEY1` or `KEY2` from the Azure configuration website.

![azureEnvExample.png](functions/images/azureEnvExample.png)


<a id="get-started"></a>
# Get Started

First, load the environment file using the [`loadenv`](https://www.mathworks.com/help/matlab/ref/loadenv.html) function.

```matlab
loadenv(".env")
```

Connect to Azure OpenAI Service using the [`azureChat`](functions/azureChat.md) function and generate text using the [`generate`](functions/generate.md) function.

```matlab
model = azureChat;
generate(model,"Why is a raven like a writing desk?")
```

```matlabTextOutput
ans = 
    "The phrase "Why is a raven like a writing desk?" originates from Lewis Carroll's "Alice's Adventures in Wonderland," specifically from the Mad Hatter's riddle during the tea party scene. Carroll himself admitted that he didn't have an answer when he wrote it, leading to various fanciful interpretations and answers over the years.
     
     One common humorous answer is: "Because they both produce notes." This playful connection highlights the absurdity and whimsy characteristic of Carroll's work. The riddle has since become a symbol of nonsensical logic and the surreal world of the story. If you'd like more interpretations or insights, feel free to ask!"

```

For more examples of how to generate text using LLMs with MATLAB, see for instance:

-  [Process Generated Text in Real Time by Using ChatGPT in Streaming Mode](../examples/ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.md) 
-  [Summarize Large Documents Using ChatGPT and MATLAB](../examples/SummarizeLargeDocumentsUsingChatGPTandMATLAB.md) (requires Text Analytics Toolbox™) 
-  [Retrieval\-Augmented Generation Using ChatGPT and MATLAB](../examples/RetrievalAugmentedGenerationUsingChatGPTandMATLAB.md) (requires Text Analytics Toolbox) 

<a id="manage-chat-history"></a>
# Manage Chat History

Manage and store messages in a conversation using the [`messageHistory`](functions/messageHistory.md) function. Use this to create a chatbot, use few\-shot prompting, or to facilitate workflows that require more than a single LLM call, such as tool calling.


First, load the environment file using the [`loadenv`](https://www.mathworks.com/help/matlab/ref/loadenv.html) function.

```matlab
loadenv(".env")
```

Connect to Azure OpenAI Service using the [`azureChat`](functions/azureChat.md) function.

```matlab
model = azureChat("You are a helpful assistant.");
```

Initialize the message history.

```matlab
messages = messageHistory;
```

Add a user message to the message history.

```matlab
messages = addUserMessage(messages,"What is the precise definition of a treble crochet stitch?");
```

Generate a response from the message history.

```matlab
[generatedText,completeOutput] = generate(model,messages)
```

```matlabTextOutput
generatedText = 
    "A treble crochet stitch (also known as triple crochet) is a basic crochet stitch that creates a tall and open texture. Here is the precise definition and steps involved in making a treble crochet stitch:
     
1. **Yarn Over**: Begin by making two yarn overs—this means wrapping the yarn around the hook twice.
     
     2. **Insert Hook**: Insert the hook into the stitch or space where you want to create the treble crochet.
     
     3. **Yarn Over and Pull Through**: Yarn over again (you now have four loops on the hook) and pull the yarn through the stitch. This completes the first part of the stitch, bringing you to three loops on the hook.
     
     4. **Yarn Over and Pull Through Two**: Yarn over and pull through the first two loops on the hook. This leaves you with two loops on the hook.
     
     5. **Yarn Over and Pull Through Two Again**: Yarn over once more and pull through the next two loops on the hook. You now have one loop remaining on the hook. 
     
     This completes one treble crochet stitch. The final result is a height that is approximately three times that of a single crochet stitch, creating an open, lacy look in your crochet project.
     
     In summary, the steps are:
1. Yarn over twice.
     2. Insert hook into stitch.
     3. Pull through (4 loops).
     4. Yarn over and pull through 2 (3 loops remaining).
     5. Yarn over and pull through 2 (2 loops remaining).
     6. Yarn over and pull through the last 2 loops (1 loop remaining). 
     
     You can repeat these steps to create additional treble crochet stitches as needed."

completeOutput = struct with fields:
    content: 'A treble crochet stitch (also known as triple crochet) is a basic crochet stitch that creates a tall and open texture. Here is the precise definition and steps involved in making a treble crochet stitch:↵↵1. **Yarn Over**: Begin by making two yarn overs—this means wrapping the yarn around the hook twice.↵↵2. **Insert Hook**: Insert the hook into the stitch or space where you want to create the treble crochet.↵↵3. **Yarn Over and Pull Through**: Yarn over again (you now have four loops on the hook) and pull the yarn through the stitch. This completes the first part of the stitch, bringing you to three loops on the hook.↵↵4. **Yarn Over and Pull Through Two**: Yarn over and pull through the first two loops on the hook. This leaves you with two loops on the hook.↵↵5. **Yarn Over and Pull Through Two Again**: Yarn over once more and pull through the next two loops on the hook. You now have one loop remaining on the hook. ↵↵This completes one treble crochet stitch. The final result is a height that is approximately three times that of a single crochet stitch, creating an open, lacy look in your crochet project.↵↵In summary, the steps are:↵1. Yarn over twice.↵2. Insert hook into stitch.↵3. Pull through (4 loops).↵4. Yarn over and pull through 2 (3 loops remaining).↵5. Yarn over and pull through 2 (2 loops remaining).↵6. Yarn over and pull through the last 2 loops (1 loop remaining). ↵↵You can repeat these steps to create additional treble crochet stitches as needed.'
    refusal: []
       role: 'assistant'

```

Add the response message to the message history.

```matlab
messages = addResponseMessage(messages,completeOutput);
```

Ask a follow\-up question by adding another user message to the message history.

```matlab
messages = addUserMessage(messages,"When was it first invented?");
```

Generate a response from the message history.

```matlab
generate(model,messages)
```

```matlabTextOutput
ans = 
    "The precise origins of the treble crochet stitch are difficult to attribute to a specific time or date, as crochet itself has a long and varied history. Crochet as a technique is believed to have emerged in the early 19th century, gaining popularity in Europe around the 1800s. It is thought to have roots in older forms of needlework and lace-making.
     
     The term "treble crochet" and the specific technique as we know it likely evolved alongside the development of crochet patterns and terminology. While crochet hooks made from various materials were in use much earlier, the distinct classifications of stitches—including single crochet, double crochet, and treble crochet—became standardized with the publication of crochet pattern books.
     
     The first recorded crochet patterns appeared in the early 19th century, and by the mid-19th century, books like "The Art of Crocheting" by Mademoiselle Riego de la Branchardière in the 1840s helped popularize and define the craft more formally.
     
     Overall, while it's challenging to pinpoint an exact date for the invention of the treble crochet stitch, it is generally accepted to be part of the crochet techniques that developed significantly in the 19th century."

```

For another example of how to use and manage the message history with LLMs with MATLAB, see the [Create Simple ChatBot](../examples/CreateSimpleChatBot.md) example (requires Text Analytics Toolbox).

<a id="images"></a>
# Images

Use Azure OpenAI Service to generate text based on image inputs.


Load a sample image from Wikipedia. Use the `imread` function to read images from URLs or filenames.

```matlab
image_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg';
im = imread(image_url);
figure
imshow(im)
```

![boardwalk.png](functions/images/boardwalk.png)

Load the environment file using the [`loadenv`](https://www.mathworks.com/help/matlab/ref/loadenv.html) function.

```matlab
loadenv(".env")
```

Set up connection to Azure OpenAI Service.

```matlab
model = azureChat;
```

Initialize the message history. Add a user prompt, along with the image, to the message history using the [`addUserMessageWithImages`](functions/addUserMessageWithImages.md) function.

```matlab
messages = messageHistory;
messages = addUserMessageWithImages(messages,"Please describe the image.", string(image_url));
```

Generate a response.

```matlab
generate(model,messages)
```

```matlabTextOutput
ans = 
    "The image depicts a serene outdoor scene featuring a wooden boardwalk traversing through a lush green field. The boardwalk, made up of planks, leads into the distance, flanked by vibrant grasses that sway gently in the breeze. On either side of the path, the grass appears thick and healthy, suggesting a well-maintained natural area. 
     
     In the background, there are trees and shrubbery, adding varied shades of green to the landscape. The sky above is expansive and blue, dotted with fluffy clouds that create a picturesque atmosphere. Soft sunlight casts a warm glow over the entire scene, enhancing the colors of the grass and the boardwalk. The overall feel of the image is peaceful and inviting, suggesting a perfect spot for a leisurely walk or a moment of tranquility in nature."

```

<a id="json-formatted-and-structured-output"></a>
# JSON\-Formatted and Structured Output

For some workflows, it is useful to generate text in a specific format. For example, a predictable output format allows you to more easily analyze the generated output.

You can specify the format either by using JSON mode, or by using structured outputs, depending on what the model supports. Both generate text containing JSON code. For more information about JSON mode, see [https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/json-mode](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/json-mode). For more information about structured outputs, see [https://platform.openai.com/docs/guides/structured-outputs](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/structured-outputs).

<a id="json-mode"></a>
## JSON Mode

To run an LLM in JSON mode, set the `ResponseFormat` name\-value argument of [`azureChat`](functions/azureChat.md) or [`generate`](functions/generate.md) to `"json"`. To configure the format of the generated JSON code, describe the format using natural language and provide it to the model either in the system prompt or as a user message. The prompt or message describing the format must contain the word `"json"` or `"JSON"`.

<a id="structured-output"></a>
## Structured Output

To use structured outputs, rather than describing the required format using natural language, you provide the model with a valid JSON schema.


In LLMs with MATLAB, you can specify the structure of the output in two different ways.

-  Specify a valid JSON Schema directly. 
-  Specify an example structure array that adheres to the required output format. The software automatically generates the corresponding JSON Schema and provides this to the LLM. Then, the software automatically converts the output of the LLM back into a structure array. 

To do this, set the `ResponseFormat` name\-value argument of [`azureChat`](functions/azureChat.md) or [`generate`](functions/generate.md) to:

-  A string scalar containing a valid JSON Schema. 
-  A structure array containing an example that adheres to the required format, for example: `ResponseFormat=struct("Name","Rudolph","NoseColor",[255 0 0])` 

Load the environment file using the [`loadenv`](https://www.mathworks.com/help/matlab/ref/loadenv.html) function.

```matlab
loadenv(".env")
```

Create a sample output structure.

```matlab
sampleOutput = struct("Animal","Penguin","CanFly",false);
```

Connect to Azure OpenAI Service.

```matlab
model = azureChat;
```

Generate structured output.

```matlab
generate(model,"Please name a random green animal and tell me whether it can fly.",ResponseFormat=sampleOutput)
```

```matlabTextOutput
ans = struct with fields:
    Animal: "Green Tree Frog"
    CanFly: 0

```

For an example of how to use structured output with LLMs with MATLAB, see [Analyze Sentiment in Text Using ChatGPT and Structured Output](../examples/AnalyzeSentimentinTextUsingChatGPTwithStructuredOutput.md).

<a id="tool-calling"></a>
# Tool Calling

Some large language models can suggest calls to a tool that you have, such as a MATLAB function, in their generated output. An LLM does not execute the tool itself. Instead, the model encodes the name of the tool and the name and value of any input arguments. You can then write scripts that automate the tool calls suggested by the LLM.


To use tool calling, specify the `ToolChoice` name\-value argument of the [`azureChat`](functions/azureChat.md) function.


Load the environment file using the [`loadenv`](https://www.mathworks.com/help/matlab/ref/loadenv.html) function.

```matlab
loadenv(".env")
```

Create an `openAIFunction` object that represents the [`sind`](https://www.mathworks.com/help/matlab/ref/sind.html) function. The `sind` function has a single input argument, `x`, representing the input angle in degrees.

```matlab
f = openAIFunction("sind","Sine of argument in degrees");
f = addParameter(f,"x",type="number",description="Angle in degrees");
```

Connect to Azure OpenAI Service. Pass the `openAIFunction` object `f` as an input argument.

```matlab
model = azureChat("You are a helpful assistant.",Tools=f);
```

Initialize the message history. Add a user message to the message history.

```matlab
messages = messageHistory;
messages = addUserMessage(messages,"What is the sine of thirty?");
```

Generate a response based on the message history.

```matlab
[~,completeOutput] = generate(model,messages)
```

```matlabTextOutput
completeOutput = struct with fields:
       content: []
       refusal: []
          role: 'assistant'
    tool_calls: [1x1 struct]

```

The model has not generated any text. Instead, it has detected a function call, `completeOutput.tool_calls`.


Add the response to the message history.

```matlab
messages = addResponseMessage(messages,completeOutput);
```

Extract the tool call ID and the name of the called function.

```matlab
toolCallID = string(completeOutput.tool_calls.id);
functionCalled = string(completeOutput.tool_calls.function.name);
```

Make sure that the model is calling the correct function. Even with only a single function, large language models can hallucinate function calls to fictitious functions.


Extract the input argument values from the complete output using the [`jsondecode`](https://www.mathworks.com/help/matlab/ref/jsondecode.html) function. Compute the sine of the generated argument value and add the result to the message history using the `addToolMessage` function.

```matlab
if functionCalled == "sind"
    args = jsondecode(completeOutput.tool_calls.function.arguments);
    result = sind(args.x)
    messages = addToolMessage(messages,toolCallID,functionCalled,"x="+result);
end
```

```matlabTextOutput
result = 0.5000
```

Finally, generate a natural language response.

```matlab
generate(model,messages)
```

```matlabTextOutput
ans = "The sine of thirty degrees is 0.5."
```

-  [Analyze Scientific Papers Using ChatGPT Function Calls](../examples/AnalyzeScientificPapersUsingFunctionCalls.md) 
-  [Analyze Text Data Using Parallel Function Calls with ChatGPT](../examples/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.md)

<a id="see-also"></a>
# See Also

[azureChat](functions/azureChat.md) | [generate](functions/generate.md) | [openAIFunction](functions/openAIFunction.md) | [addParameter](functions/addParameter.md) | [messageHistory](functions/messageHistory.md) | [addSystemMessage](functions/addSystemMessage.md) | [addUserMessage](functions/addUserMessage.md) | [addUserMessageWithImages](functions/addUserMessageWithImages.md) | [addToolMessage](functions/addToolMessage.md) | [addResponseMessage](functions/addResponseMessage.md) | [removeMessage](functions/removeMessage.md)

<a id="examples"></a>
# Examples

- [Process Generated Text in Real Time by Using ChatGPT in Streaming Mode](../examples/ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.md) 
- [Summarize Large Documents Using ChatGPT and MATLAB](../examples/SummarizeLargeDocumentsUsingChatGPTandMATLAB.md) (requires Text Analytics Toolbox)
- [Create Simple ChatBot](../examples/CreateSimpleChatBot.md) (requires Text Analytics Toolbox)
- [Analyze Scientific Papers Using ChatGPT Function Calls](../examples/AnalyzeScientificPapersUsingFunctionCalls.md)
- [Analyze Sentiment in Text Using ChatGPT and Structured Output](../examples/AnalyzeSentimentinTextUsingChatGPTwithStructuredOutput.md)
- [Analyze Text Data Using Parallel Function Calls with ChatGPT](../examples/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.md)
- [Retrieval-Augmented Generation Using ChatGPT and MATLAB](../examples/RetrievalAugmentedGenerationUsingChatGPTandMATLAB.md) (requires Text Analytics Toolbox)
- [Describe Images Using ChatGPT](../examples/DescribeImagesUsingChatGPT.md)

*Copyright 2024-2025 The MathWorks, Inc.*
