
# Ollama

Connect to [Ollama™](https://ollama.com/)  models from MATLAB® locally or nonlocally.

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

Connecting to Ollama models using this add\-on requires an installed version of Ollama, as well as installed versions of the models you want to use. 

1.  **Install Ollama.** For information on how to install Ollama, see [https://ollama.com/download](https://ollama.com/download).
2. **Install Model.** If you have Ollama installed, then you can install models from the MATLAB Command Window using the `"ollama pull"` command. For example, to install Mistral, run this code.
```
>> !ollama pull mistral
```

For information on which Ollama models you have installed, use the `models` method of the `ollamaChat` class:
```matlab
listOfAvailableModels = ollamaChat.models;
```

<a id="get-started"></a>
# Get Started

Connect to Ollama using the [`ollamaChat`](functions/ollamaChat.md) function and generate text using the [`generate`](functions/generate.md) function. Optionally specify a system prompt.

```matlab
model = ollamaChat("mistral","You are a helpful assistant.");
generate(model,"Who would win a footrace, a snail or a blue whale?")
```

```matlabTextOutput
ans = " A blue whale cannot compete in a footrace as it lives and moves primarily in water, not on land. If we were to compare the speed between a snail and an animal that can move on land, like a cheetah for example, a cheetah would win hands down. Cheetahs have been recorded running at speeds up to 70 mph (112 km/h), while the maximum speed achievable by the average garden snail is about 0.03 mph (0.05 km/h)."
```

By default, the `ollamaChat` function connects to a local server. To use a remote Ollama server, specify the server name and port number using the `Endpoint` name\-value argument.

```
>> model = ollamaChat("mistral",Endpoint="myOllamaServer:12345");
```

For more examples of how to generate text using Ollama from MATLAB, see for instance:

-  [Process Generated Text in Real Time by Using Ollama in Streaming Mode](../examples/ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode.md) 
-  [Retrieval\-Augmented Generation Using Ollama and MATLAB](../examples/RetrievalAugmentedGenerationUsingOllamaAndMATLAB.md) (requires Text Analytics Toolbox™) 

<a id="manage-chat-history"></a>
# Manage Chat History

Manage and store messages in a conversation using the [`messageHistory`](functions/messageHistory.md) function. Use this to create a chatbot, use few\-shot prompting, or to facilitate workflows that require more than a single LLM call, such as tool calling.


Connect to Ollama using the [`ollamaChat`](functions/ollamaChat.md) function.

```matlab
model = ollamaChat("mistral");
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
generatedText = " A Treble Crochet Stitch (abbreviated as tr or trbl in patterns) is one of the basic stitches used in crocheting. It is formed by yarn-overing twice and inserting the hook under two loops on the previous row, then pulling up a loop through all six loops on the hook: one loop from each yarn over and one loop from each of the two adjacent stitches below. This combination creates a taller and looser stitch compared to a double crochet (dc) stitch. The treble crochet stitch is often used for increasing and creating textured patterns in crocheting projects."
completeOutput = struct with fields:
       role: 'assistant'
    content: ' A Treble Crochet Stitch (abbreviated as tr or trbl in patterns) is one of the basic stitches used in crocheting. It is formed by yarn-overing twice and inserting the hook under two loops on the previous row, then pulling up a loop through all six loops on the hook: one loop from each yarn over and one loop from each of the two adjacent stitches below. This combination creates a taller and looser stitch compared to a double crochet (dc) stitch. The treble crochet stitch is often used for increasing and creating textured patterns in crocheting projects.'

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
ans = " The exact origins of crochet are unclear, but it is believed that it originated around the mid-16th century. Various types of crochet including treble stitches were developed and refined over time by different cultures such as Egyptians, Arabs, Persians, and Europeans. The modern version of crocheting using a hook and yarn became popular in Europe during the 19th century with the spread of the Industrial Revolution, which made it easier to produce thread and hooks on a mass scale. However, it is difficult to pinpoint the exact time when specific stitches like the treble crochet were first invented."
```

For another example of how to use and manage the message history, see the [Create Simple Ollama ChatBot](../examples/CreateSimpleOllamaChatBot.md) example (requires Text Analytics Toolbox).

<a id="images"></a>
# Images

You can use Ollama to generate text based on image inputs. For information on whether an Ollama model supports image inputs, check whether the model has the **`vision`** tag in [ollama.com/library](https://ollama.com/library). 

> [!TIP]  
> Some models that do not support image inputs allow you to specify images in the prompt, but silently ignore the images from the input.


Load a sample image from Wikipedia. Use the `imread` function to read images from URLs or filenames.

```matlab
image_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg';
im = imread(image_url);
figure
imshow(im)
```

![boardwalk.png](functions/images/boardwalk.png)

Set up the interface to Ollama using the model [Moondream](https://ollama.com/library/moondream).

```matlab
chat = ollamaChat("moondream");
```

Initialize the message history. Add a user prompt, along with the image, to the message history.

```matlab
messages = messageHistory;
messages = addUserMessageWithImages(messages,"Please describe the image.", string(image_url));
```

Generate a response.

```matlab
generate(chat,messages)
```

```matlabTextOutput
ans = 
    "
     The image shows a long walkway or boardwalk made of wood, situated between two grass fields, likely in North America as it is close to the border between the United States and Mexico. The boards for the pathway are positioned at an angle towards the left side on both parts of the walkway. This path can provide easy access to nature, offering a relaxing stroll through the lush green field."

```

<a id="json-formatted-and-structured-output"></a>
# JSON\-Formatted and Structured Output

For some workflows, it is useful to generate text in a specific format. For example, a predictable output format allows you to more easily analyze the generated output. 


You can specify the format either by using JSON mode, or by using structured outputs, depending on what the model supports. Both generate text containing JSON code. For more information on structured output in Ollama, see [https://ollama.com/blog/structured\-outputs](https://ollama.com/blog/structured-outputs).

<a id="json-mode"></a>
## JSON Mode

To run an LLM in JSON mode, set the `ResponseFormat` name\-value argument of [`ollamaChat`](functions/ollamaChat.md) or [`generate`](functions/generate.md) to `"json"`. To configure the format of the generated JSON code, describe the format using natural language and provide it to the model either in the system prompt or as a user message. The prompt or message describing the format must contain the word `"json"` or `"JSON"`.

<a id="structured-output"></a>
## Structured Output

To use structured outputs, rather than describing the required format using natural language, provide the model with a valid JSON schema.


In LLMs with MATLAB, you can specify the structure of the output in two different ways.

-  Specify a valid JSON Schema directly. 
-  Specify an example structure array that adheres to the required output format. The software automatically generates the corresponding JSON Schema and provides this to the LLM. Then, the software automatically converts the output of the LLM back into a structure array. 

To do this, set the `ResponseFormat` name\-value argument of [`ollamaChat`](functions/ollamaChat.md) or [`generate`](functions/generate.md) to:

-  A string scalar containing a valid JSON Schema. 
-  A structure array containing an example that adheres to the required format, for example: `ResponseFormat=struct("Name","Rudolph","NoseColor",[255 0 0])` 

For an example of how to use structured output with LLMs with MATLAB, see [Analyze Sentiment in Text Using ChatGPT and Structured Output](https://github.mathworks.com/development/llms-with-matlab/blob/main/examples/AnalyzeSentimentinTextUsingChatGPTwithStructuredOutput.md).

<a id="tool-calling"></a>
# Tool Calling

Some large language models can suggest calls to a tool that you have, such as a MATLAB function, in their generated output. An LLM does not execute the tool itself. Instead, the model encodes the name of the tool and the name and value of any input arguments. You can then write scripts that automate the tool calls suggested by the LLM.


To use tool calling, specify the `ToolChoice` name\-value argument of the [`ollamaChat`](functions/ollamaChat.md) function.


For information on whether an Ollama model supports tool calling, check whether the model has the **`tools`** tag in [ollama.com/library](https://ollama.com/library).


For an example of how to use tool calling with Ollama in LLMs with MATLAB, see [Analyze Text Data Using Parallel Function Calls with Ollama](/examples/AnalyzeTextDataUsingParallelFunctionCallwithOllama.md).

<a id="see-also"></a>
# See Also

[`ollamaChat`](functions/ollamaChat.md) | [`generate`](functions/generate.md) | [`openAIFunction`](functions/openAIFunction.md) | [`addParameter`](functions/addParameter.md) | [`messageHistory`](functions/messageHistory.md) | [`addSystemMessage`](functions/addSystemMessage.md) | [`addUserMessage`](functions/addUserMessage.md) | [`addUserMessageWithImages`](functions/addUserMessageWithImages.md) | [`addToolMessage`](functions/addToolMessage.md) | [`addResponseMessage`](functions/addResponseMessage.md) | [`removeMessage`](functions/removeMessage.md)


<a id="examples"></a>
# Examples

- [Process Generated Text in Real Time by Using Ollama in Streaming Mode](/examples/ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode.md) 
- [Create Simple Ollama ChatBot](/examples/CreateSimpleOllamaChatBot.md) (requires Text Analytics Toolbox)
- [Analyze Sentiment in Text Using ChatGPT and Structured Output](/examples/AnalyzeSentimentinTextUsingChatGPTwithStructuredOutput.md)
- [Analyze Text Data Using Parallel Function Calls with Ollama](/examples/AnalyzeTextDataUsingParallelFunctionCallwithOllama.md)
- [Retrieval-Augmented Generation Using Ollama and MATLAB](/examples/RetrievalAugmentedGenerationUsingOllamaAndMATLAB.md) (requires Text Analytics Toolbox)

*Copyright 2024-2025 The MathWorks, Inc.*
