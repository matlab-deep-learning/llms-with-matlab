
# Analyze Sentiment in Text Using ChatGPT™ and Structured Output

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/AnalyzeSentimentinTextUsingChatGPTwithStructuredOutput.mlx](mlx-scripts/AnalyzeSentimentinTextUsingChatGPTwithStructuredOutput.mlx) 

This example shows how to use ChatGPT for sentiment analysis and output the results in a desired format. 


To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
```

Define some text to analyze the sentiment.

```matlab
inputText = ["I can't stand homework.";
    "This sucks. I'm bored.";
    "I can't wait for Halloween!!!";
    "I am neither for nor against the idea.";
    "My cat is adorable ❤️❤️";
    "I hate chocolate";
    "More work. Great.";
    "More work. Great!"];
```

Define the system prompt.

```matlab
systemPrompt = "You are an AI designed to analyze the sentiment of the provided text and  " + ...
    "Determine whether the sentiment is positive, negative, or neutral " + ...
    "and provide a confidence score between 0 and 1.";
prompt = "Analyze the sentiment of the provided text.";
```

Define the expected output format by providing an example – when supplied with a struct as the `ResponseFormat`, `generate` will return a struct with the same field names and data types. Use a [categorical](https://www.mathworks.com/help/matlab/categorical-arrays.html) to restrict the values that can be returned to the list `["positive","negative","neutral"]`.

```matlab
prototype = struct(...
    "sentiment", categorical("positive",["positive","negative","neutral"]),...
    "confidence", 0.2)
```

```matlabTextOutput
prototype = struct with fields:
     sentiment: positive
    confidence: 0.2000

```


Create a chat object and set `ResponseFormat` to `prototype`. This example uses the model GPT\-4.1 nano.

```matlab
chat = openAIChat(systemPrompt, ResponseFormat=prototype, ModelName="gpt-4.1-nano");
```

Concatenate the prompt and input text and generate an answer with the model.

```matlab
scores = [];
for i = 1:numel(inputText)
```

Generate a response from the message. 

```matlab
    thisResponse = generate(chat,prompt + newline + newline + inputText(i));
    scores = [scores; thisResponse]; %#ok<AGROW>
end
```

Extract the content from the output structure array `scores`.

```matlab
T = struct2table(scores);
T.text = inputText;
T = movevars(T,"text","Before","sentiment")
```


| |text|sentiment|confidence|
|:--:|:--:|:--:|:--:|
|1|"I can't stand homework."|negative|0.9500|
|2|"This sucks. I'm bored."|negative|0.9500|
|3|"I can't wait for Halloween!!!"|positive|0.8500|
|4|"I am neither for nor against the idea."|neutral|0.9000|
|5|"My cat is adorable ❤️❤️"|positive|0.9500|
|6|"I hate chocolate"|negative|0.9500|
|7|"More work. Great."|negative|0.8000|
|8|"More work. Great!"|positive|0.8000|



*Copyright 2024 The MathWorks, Inc.*

