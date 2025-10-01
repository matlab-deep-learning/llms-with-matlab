# OpenAI

Connect to the [OpenAI® Chat Completions API](https://platform.openai.com/docs/guides/text-generation/chat-completions-api)  and [OpenAI Images API](https://platform.openai.com/docs/guides/images) from MATLAB®.

1. [Setup](#setup)
2. [Get Started](#get-started)
3. [Manage Chat History](#manage-chat-history)
4. [Images](#images)
   - [Describe Images](#describe-images)
   - [Generate and Edit Images](#generate-and-edit-images)
5. [JSON\-Formatted and Structured Output](#json-formatted-and-structured-output)
   - [JSON Mode](#json-mode)
   - [Structured Output](#structured-output)
6. [Tool Calling](#tool-calling)
7. [See Also](#see-also)
8. [Examples](#examples)

<a id="setup"></a>
# Setup

Using the OpenAI API requires an OpenAI API key. For information on how to obtain an OpenAI API key, as well as pricing, terms and conditions of use, and information about available models, see the OpenAI documentation at [https://platform.openai.com/docs/overview](https://platform.openai.com/docs/overview).


To connect to the OpenAI API from MATLAB using LLMs with MATLAB, specify the OpenAI® API key as an environment variable and save it to a file called ".env".


![envExample.png](functions/images/envExample.png)


To connect to OpenAI, the ".env" file must be on the search path.

<a id="get-started"></a>
# Get Started

First, load the environment file using the [`loadenv`](https://www.mathworks.com/help/matlab/ref/loadenv.html) function.

```matlab
loadenv(".env")
```

Connect to the OpenAI Chat Completion API using the [`openAIChat`](functions/openAIChat.md) function and generate text using the [`generate`](functions/generate.md) function.

```matlab
model = openAIChat("You are a helpful assistant.",ModelName="gpt-4o-mini");
generate(model,"Why is a raven like a writing desk?")
```

```matlabTextOutput
ans = 
    "The riddle "Why is a raven like a writing desk?" originates from Lewis Carroll's "Alice's Adventures in Wonderland." In the story, the Mad Hatter poses this riddle, but he does not provide an answer, leaving it open to interpretation.
     
     Over the years, various humorous answers have been proposed, such as:
     
     - "Because both have quills."
     - "Because they both produce notes."
     - "Because they both can be inky."
     
     Ultimately, the riddle is meant to be nonsensical, reflecting the whimsical and absurd nature of the story. Carroll himself later provided an answer in a preface to a later edition of the book, stating that there is no answer, emphasizing the playful nature of language and logic in his work."

```

For more examples of how to generate text using the OpenAI Chat Completion API from MATLAB, see for instance:

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

Connect to the OpenAI Chat Completion API using the [`openAIChat`](functions/openAIChat.md) function.

```matlab
model = openAIChat("You are a helpful assistant.",ModelName="gpt-4o-mini");
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
    "A treble crochet stitch (often abbreviated as "tr") is a basic crochet stitch that creates a tall and lacey fabric. The precise definition and process for creating a treble crochet stitch is as follows:
     
1. **Yarn Over**: Start by yarn over (wrap the yarn around your hook) twice.
     
     2. **Insert Hook**: Insert the hook into the stitch or space where you want to make the stitch.
     
     3. **Yarn Over and Pull Through**: yarn over again and pull the yarn through the stitch or space. You will have four loops on your hook.
     
     4. **Yarn Over and Pull Through Two Loops**: Yarn over and pull through the first two loops on your hook. You will now have three loops remaining on your hook.
     
     5. **Yarn Over and Pull Through Two Loops Again**: Yarn over again and pull through the next two loops. You will now be left with two loops on your hook.
     
     6. **Final Yarn Over and Pull Through**: Yarn over one last time and pull through the remaining two loops on your hook.
     
     You have now completed one treble crochet stitch, and this stitch is taller than a double crochet stitch and adds a delicate texture to your work. 
     
     In summary, a treble crochet stitch involves yarn overs before and after pulling through loops to create a height that makes it distinctive from other crochet stitches."

completeOutput = struct with fields:
       role: 'assistant'
    content: 'A treble crochet stitch (often abbreviated as "tr") is a basic crochet stitch that creates a tall and lacey fabric. The precise definition and process for creating a treble crochet stitch is as follows:↵↵1. **Yarn Over**: Start by yarn over (wrap the yarn around your hook) twice.↵↵2. **Insert Hook**: Insert the hook into the stitch or space where you want to make the stitch.↵↵3. **Yarn Over and Pull Through**: yarn over again and pull the yarn through the stitch or space. You will have four loops on your hook.↵↵4. **Yarn Over and Pull Through Two Loops**: Yarn over and pull through the first two loops on your hook. You will now have three loops remaining on your hook.↵↵5. **Yarn Over and Pull Through Two Loops Again**: Yarn over again and pull through the next two loops. You will now be left with two loops on your hook.↵↵6. **Final Yarn Over and Pull Through**: Yarn over one last time and pull through the remaining two loops on your hook.↵↵You have now completed one treble crochet stitch, and this stitch is taller than a double crochet stitch and adds a delicate texture to your work. ↵↵In summary, a treble crochet stitch involves yarn overs before and after pulling through loops to create a height that makes it distinctive from other crochet stitches.'
    refusal: []

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
    "The precise origins of the treble crochet stitch are difficult to pinpoint, as crochet as a craft has evolved over centuries and lacks detailed historical records. Crochet itself is believed to have originated in the early 19th century, with a significant development occurring in Europe. 
     
     The modern form of crochet, incorporating various stitches including the treble stitch, became popular in the 19th century during the Victorian era. This period saw a surge in the use of lace-making techniques, and crochet was often used to replicate fine lace patterns. The terminology for crochet stitches, including the treble crochet, was standardized through various publications and instructional guides in the late 1800s.
     
     While the specific inventors of the treble crochet stitch are unknown, it is part of the rich tapestry of crochet techniques that evolved as lace-making and textile arts grew in popularity. Thus, treble crochet and its use in patterns became more formalized in crafting literature throughout the 19th century."

```

For another example of how to use and manage the message history, see the [Create Simple ChatBot](../examples/CreateSimpleChatBot.md) example (requires Text Analytics Toolbox).

<a id="images"></a>
# Images

Use the OpenAI Chat Completions API to generate text based on image inputs. Use the OpenAI Image Generation API to generate and edit images.

<a id="describe-images"></a>
## Describe Images

To generate text based on image inputs using the OpenAI Chat Completions API from MATLAB, add the image to the message history using the [`addUserMessageWithImages`](functions/addUserMessageWithImages.md) function.


For an example of how to describe images using the OpenAI Chat Completions API, see [Describe Images Using ChatGPT](../examples/DescribeImagesUsingChatGPT.md).

<a id="generate-and-edit-images"></a>
## Generate and Edit Images

Connect to OpenAI Image Generation API from MATLAB using the [openAIImages](functions/openAIImages.md) function.


First, load the environment file using the [`loadenv`](https://www.mathworks.com/help/matlab/ref/loadenv.html) function.

```matlab
loadenv(".env")
```

Connect to the OpenAI Images API.

```matlab
model = openAIImages(ModelName="dall-e-2");
```

Generate and display an image based on a natural language prompt using the [`openAIImages.generate`](functions/openAIImages.generate.md) function.

```matlab
im = generate(model,"Draw an intellectual octopus.");
imshow(im{1})
```

![octopus.png](functions/images/octopus.png)

For more examples of how to generate and edit images using OpenAI from MATLAB, see:

-  [Using DALL·E To Edit Images](../examples/UsingDALLEToEditImages.md) 
-  [Using DALL·E To Generate Images](../examples/UsingDALLEToGenerateImages.md) 

<a id="json-formatted-and-structured-output"></a>
# JSON\-Formatted and Structured Output

For some workflows, it is useful to generate text in a specific format. For example, a predictable output format allows you to more easily analyze the generated output.


You can specify the format either by using JSON mode, or by using structured outputs, depending on what the model supports. Both generate text containing JSON code. For more information about JSON mode, see [https://platform.openai.com/docs/guides/structured\-outputs\#json\-mode](https://platform.openai.com/docs/guides/structured-outputs#json-mode). For more information about structured outputs, see [https://platform.openai.com/docs/guides/structured\-outputs](https://platform.openai.com/docs/guides/structured-outputs).

<a id="json-mode"></a>
## JSON Mode

To run an LLM in JSON mode, set the `ResponseFormat` name\-value argument of [`openAIChat`](functions/openAIChat.md) or [`generate`](functions/generate.md) to `"json"`. To configure the format of the generated JSON code, describe the format using natural language and provide it to the model either in the system prompt or as a user message. The prompt or message describing the format must contain the word `"json"` or `"JSON"`.

<a id="structured-output"></a>
## Structured Output

To use structured outputs, rather than describing the required format using natural language, you provide the model with a valid JSON schema.


In LLMs with MATLAB, you can specify the structure of the output in two different ways.

-  Specify a valid JSON Schema directly. 
-  Specify an example structure array that adheres to the required output format. The software automatically generates the corresponding JSON Schema and provides this to the LLM. Then, the software automatically converts the output of the LLM back into a structure array. 

To do this, set the `ResponseFormat` name\-value argument of [`openAIChat`](functions/openAIChat.md) or [`generate`](functions/generate.md) to:

-  A string scalar containing a valid JSON Schema. 
-  A structure array containing an example that adheres to the required format, for example: `ResponseFormat=struct("Name","Rudolph","NoseColor",[255 0 0])` 

For an example of how to use structured output with LLMs with MATLAB, see [Analyze Sentiment in Text Using ChatGPT and Structured Output](../examples/AnalyzeSentimentinTextUsingChatGPTwithStructuredOutput.md).

<a id="tool-calling"></a>
# Tool Calling

Some large language models can suggest calls to a tool that you have, such as a MATLAB function, in their generated output. An LLM does not execute the tool itself. Instead, the model encodes the name of the tool and the name and value of any input arguments. You can then write scripts that automate the tool calls suggested by the LLM.


To use tool calling, specify the `Tools` name\-value argument of the [`openAIChat`](functions/openAIChat.md) function.

For some examples of how to use tool calling with this add\-on, see:
-  [Analyze Scientific Papers Using ChatGPT Function Calls](../examples/AnalyzeScientificPapersUsingFunctionCalls.md) 
-  [Analyze Text Data Using Parallel Function Calls with ChatGPT](../examples/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.md)
-  [Solve Simple Math Problem Using AI Agent](/examples/SolveSimpleMathProblemUsingAIAgent.md)
-  [Fit Polynomial to Data Using AI Agent](/examples/FitPolynomialToDataUsingAIAgentExample.md) (requires Curve Fitting Toolbox™)

<a id="see-also"></a>
# See Also

[openAIChat](functions/openAIChat.md) | [generate](functions/generate.md) | [openAIFunction](functions/openAIFunction.md) | [addParameter](functions/addParameter.md) | [openAIImages](functions/openAIImages.md) | [openAIImages.generate](functions/openAIImages.generate.md) | [edit](functions/edit.md) | [createVariation](functions/createVariation.md) | [messageHistory](functions/messageHistory.md) | [addSystemMessage](functions/addSystemMessage.md) | [addUserMessage](functions/addUserMessage.md) | [addUserMessageWithImages](functions/addUserMessageWithImages.md) | [addToolMessage](functions/addToolMessage.md) | [addResponseMessage](functions/addResponseMessage.md) | [removeMessage](functions/removeMessage.md)

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
- [Using DALL·E To Edit Images](../examples/UsingDALLEToEditImages.md)
- [Using DALL·E To Generate Images](../examples/UsingDALLEToGenerateImages.md)
- [Solve Simple Math Problem Using AI Agent](/examples/SolveSimpleMathProblemUsingAIAgent.md)
- [Fit Polynomial to Data Using AI Agent](/examples/FitPolynomialToDataUsingAIAgentExample.md) (requires Curve Fitting Toolbox)

*Copyright 2024-2025 The MathWorks, Inc.*
