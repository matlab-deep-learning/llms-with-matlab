
# Large Language Models (LLMs) with MATLAB

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab-deep-learning/llms-with-matlab) [![View Large Language Models (LLMs) with MATLAB on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/163796-large-language-models-llms-with-matlab) 

Large Language Models (LLMs) with MATLAB lets you connect to large language model APIs using MATLAB®. 


You can connect to:

-  [OpenAI® Chat Completions API](https://platform.openai.com/docs/guides/text-generation/chat-completions-api) — For example, connect to ChatGPT™. 
-  [OpenAI Images API](https://platform.openai.com/docs/guides/images) — For example, connect to DALL·E™. 
-  [Azure® OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/) — Connect to OpenAI models from Azure. 
-  [Ollama™](https://ollama.com/) — Connect to models locally or nonlocally. 

Using this add-on, you can:

-  Generate responses to natural language prompts.
-  Manage chat history.
-  Generate JSON\-formatted and structured output. 
-  Use tool calling.  
-  Generate, edit, and describe images. 

For more information about the features in this add-on, see the documentation in the [`doc`](/doc) directory.

# Installation

Using this add-on requires MATLAB R2024a or newer.

## Use MATLAB Online

You can use the add-on in MATLAB Online™ by clicking this link: [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=matlab-deep-learning/llms-with-matlab) 

In MATLAB Online, you can connect to OpenAI and Azure. To connect to Ollama, use an installed version of MATLAB and install the add\-on using the Add\-On Explorer or by cloning the GitHub™ repository.

## Install using Add\-On Explorer

The recommended way of using the add-on on an installed version of MATLAB is to use the Add\-On Explorer.

1. In MATLAB, go to the **Home** tab, and in the **Environment** section, click the **Add\-Ons** icon.
2. In the Add\-On Explorer, search for "Large Language Models (LLMs) with MATLAB".
3. Select **Install**.
## Install by Cloning GitHub Repository

Alternatively, to use the add-on on an installed version of MATLAB, you can clone the GitHub repository. In the MATLAB Command Window, run this command:

```
>> !git clone https://github.com/matlab-deep-learning/llms-with-matlab.git
```

To run code from the add-on outside of the installation directory, if you install the add-on by cloning the GitHub repository, then you must add the path to the installation directory.

```
>> addpath("path/to/llms-with-matlab")
```
# Get Started with External APIs

For more information about how to connect to the different APIs from MATLAB, including installation requirements, see:
- [OpenAI](/doc/OpenAI.md)
- [Azure OpenAI Service](/doc/Azure.md)
- [Ollama](/doc/Ollama.md)

# Examples

- [Process Generated Text in Real Time by Using ChatGPT in Streaming Mode](/examples/ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.md) 
- [Process Generated Text in Real Time by Using Ollama in Streaming Mode](/examples/ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode.md) 
- [Summarize Large Documents Using ChatGPT and MATLAB](/examples/SummarizeLargeDocumentsUsingChatGPTandMATLAB.md) (requires Text Analytics Toolbox™)
- [Create Simple ChatBot](/examples/CreateSimpleChatBot.md) (requires Text Analytics Toolbox)
- [Create Simple Ollama ChatBot](/examples/CreateSimpleOllamaChatBot.md) (requires Text Analytics Toolbox)
- [Analyze Scientific Papers Using ChatGPT Function Calls](/examples/AnalyzeScientificPapersUsingFunctionCalls.md)
- [Analyze Sentiment in Text Using ChatGPT and Structured Output](/examples/AnalyzeSentimentinTextUsingChatGPTwithStructuredOutput.md)
- [Analyze Text Data Using Parallel Function Calls with ChatGPT](/examples/AnalyzeTextDataUsingParallelFunctionCallwithChatGPT.md)
- [Analyze Text Data Using Parallel Function Calls with Ollama](/examples/AnalyzeTextDataUsingParallelFunctionCallwithOllama.md)
- [Retrieval-Augmented Generation Using ChatGPT and MATLAB](/examples/RetrievalAugmentedGenerationUsingChatGPTandMATLAB.md) (requires Text Analytics Toolbox)
- [Retrieval-Augmented Generation Using Ollama and MATLAB](/examples/RetrievalAugmentedGenerationUsingOllamaAndMATLAB.md) (requires Text Analytics Toolbox)
- [Describe Images Using ChatGPT](/examples/DescribeImagesUsingChatGPT.md)
- [Using DALL·E To Edit Images](/examples/UsingDALLEToEditImages.md)
- [Using DALL·E To Generate Images](/examples/UsingDALLEToGenerateImages.md)

# Functions
| **Function**   | **Description**  |
| :-- | :-- | 
| [openAIChat](/doc/functions/openAIChat.md) | Connect to OpenAI Chat Completion API from MATLAB |
| [azureChat](/doc/functions/azureChat.md) | Connect to Azure OpenAI Services Chat Completion API from MATLAB |
| [ollamaChat](/doc/functions/ollamaChat.md) | Connect to Ollama Server from MATLAB |
| [generate](/doc/functions/generate.md) | Generate output from large language models |
| [openAIFunction](/doc/functions/openAIFunction.md) | Use Function Calls from MATLAB |
| [addParameter](/doc/functions/addParameter.md) | Add input argument to `openAIFunction` object |
| [openAIImages](/doc/functions/openAIImages.md) | Connect to OpenAI Image Generation API from MATLAB |
| [openAIImages.generate](/doc/functions/openAIImages.generate.md) | Generate image using OpenAI image generation API |
| [edit](/doc/functions/edit.md) | Edit images using DALL·E 2 |
| [createVariation](/doc/functions/createVariation.md) | Generate image variations using DALL·E 2 |
| [messageHistory](/doc/functions/messageHistory.md) | Manage and store messages in a conversation |
| [addSystemMessage](/doc/functions/addSystemMessage.md) | Add system message to message history |
| [addUserMessage](/doc/functions/addUserMessage.md) | Add user message to message history |
| [addUserMessageWithImages](/doc/functions/addUserMessageWithImages.md) | Add user message with images to message history |
| [addToolMessage](/doc/functions/addToolMessage.md) | Add tool message to message history |
| [addResponseMessage](/doc/functions/addResponseMessage.md) | Add response message to message history |
| [removeMessage](/doc/functions/removeMessage.md) | Remove message from message history |

## License

The license is available in the [license.txt](license.txt) file in this GitHub repository.

## Community Support
[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2023-2025 The MathWorks, Inc.
