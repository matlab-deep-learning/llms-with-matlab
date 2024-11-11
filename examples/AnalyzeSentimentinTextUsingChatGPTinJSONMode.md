
# Analyze Sentiment in Text Using ChatGPT™ in JSON Mode

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/AnalyzeSentimentinTextUsingChatGPTinJSONMode.mlx](mlx-scripts/AnalyzeSentimentinTextUsingChatGPTinJSONMode.mlx) 

This example shows how to use ChatGPT for sentiment analysis and output the results in JSON format. 


To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
addpath('../..')
```

Define some text to analyze the sentiment.

```matlab
inputText = ["I can't stand homework.";
    "This sucks. I'm bored.";
    "I can't wait for Halloween!!!";
    "I am neigher for or against the idea.";
    "My cat is adorable ❤️❤️";
    "I hate chocolate"];
```

Define the expected output JSON Schema.

```matlab
jsonSchema = '{"sentiment": "string (positive, negative, neutral)","confidence_score": "number (0-1)"}';
```

Define the system prompt, combining your instructions and the JSON Schema. In order for the model to output JSON, you need to specify that in the prompt, for example, adding *"designed to output to JSON"*  to the prompt.

```matlab
systemPrompt = "You are an AI designed to output to JSON. You analyze the sentiment of the provided text and  " + ...
    "Determine whether the sentiment is positive, negative, or neutral and provide a confidence score using " + ...
    "the schema: " + jsonSchema;
prompt = "Analyze the sentiment of the provided text. " + ...
    "Determine whether the sentiment is positive, negative," + ...
    " or neutral and provide a confidence score";
```

Create a chat object with `ModelName gpt-3.5-turbo` and specify `ResponseFormat` as `"json".`

```matlab
model = "gpt-3.5-turbo";
chat = openAIChat(systemPrompt, ModelName=model, ResponseFormat="json");
```

Concatenate the prompt and input text and generate an answer with the model.

```matlab
scores = cell(1,numel(inputText));
for i = 1:numel(inputText)
```

Generate a response from the message. 

```matlab
    [json, message, response] = generate(chat,prompt + newline + newline + inputText(i));
    scores{i} = jsondecode(json);
end
```

Extract the data from the JSON output. 

```matlab
T = struct2table([scores{:}]);
T.text = inputText;
T = movevars(T,"text","Before","sentiment")
```
| |text|sentiment|confidence_score|
|:--:|:--:|:--:|:--:|
|1|"I can't stand homework."|'negative'|0.9500|
|2|"This sucks. I'm bored."|'negative'|0.9000|
|3|"I can't wait for Halloween!!!"|'positive'|1|
|4|"I am neigher for or against the idea."|'neutral'|1|
|5|"My cat is adorable ❤️❤️"|'positive'|0.9500|
|6|"I hate chocolate"|'negative'|1|


*Copyright 2024 The MathWorks, Inc.*

