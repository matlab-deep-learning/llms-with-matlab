
# Create Simple ChatBot

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/CreateSimpleChatBot.mlx](mlx-scripts/CreateSimpleChatBot.mlx) 

This example shows how to create a simple chatbot using the `openAIChat` and `messageHistory` functions.


When you run this example, an interactive AI chat starts in the MATLAB® Command Window. To leave the chat, type "end" or press **Ctrl+C**.

-  This example includes three steps: 
-  Define model parameters, such as the maximum word count, and a stop word. 
-  Create an openAIChat object and set up a meta prompt. 
-  Set up the chat loop. 

To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
addpath('../..') 
```
# Setup Model

Set the maximum allowable number of words per chat session and define the keyword that, when entered by the user, ends the chat session. This example uses the model `gpt-3.5-turbo`.

```matlab
wordLimit = 2000;
stopWord = "end";
modelName = "gpt-3.5-turbo";
```

Create an instance of `openAIChat` to perform the chat and `messageHistory` to store the conversation history`.`

```matlab
chat = openAIChat("You are a helpful assistant. You reply in a very concise way, keeping answers limited to short sentences.", ModelName=modelName);
messages = messageHistory;
```
# Chat loop

Start the chat and keep it going until it sees the word in `stopWord`.

```matlab
totalWords = 0;
messagesSizes = [];
```

The main loop continues indefinitely until you input the stop word or press **Ctrl+C.**

```matlab
while true
    query = input("User: ", "s");
    query = string(query);
    disp("User: " + query)
```

If the you input the stop word, display a farewell message and exit the loop.

```matlab
    if query == stopWord
        disp("AI: Closing the chat. Have a great day!")
        break;
    end

    numWordsQuery = countNumWords(query);
```

If the query exceeds the word limit, display an error message and halt execution.

```matlab
    if numWordsQuery>wordLimit
        error("Your query should have less than 2000 words. You query had " + numWordsQuery + " words")
    end
```

Keep track of the size of each message and the total number of words used so far.

```matlab
    messagesSizes = [messagesSizes; numWordsQuery]; %#ok
    totalWords = totalWords + numWordsQuery;
```

If the total word count exceeds the limit, remove messages from the start of the session until it no longer does.

```matlab
    while totalWords > wordLimit
        totalWords = totalWords - messagesSizes(1);
        messages = removeMessage(messages, 1);
        messagesSizes(1) = [];
    end
```

Add the new message to the session and generate a new response.

```matlab
    messages = addUserMessage(messages, query);
    [text, response] = generate(chat, messages);
    
    disp("AI: " + text)
```

Count the number of words in the response and update the total word count.

```matlab
    numWordsResponse = countNumWords(text);
    messagesSizes = [messagesSizes; numWordsResponse]; %#ok
    totalWords = totalWords + numWordsResponse;
```

Add the response to the session.

```matlab
    messages = addResponseMessage(messages, response);
end
```

```matlabTextOutput
User: Hello, how much do you know about physics?
AI: I am knowledgeable about various topics in physics. How can I assist you today?
User: What is torque?
AI: Torque is a measure of the rotational force applied to an object.
User: What is force?
AI: Force is a push or pull that causes an object to accelerate or change its motion.
User: What is motion?
AI: Motion is the change in position of an object over time in relation to a reference point.
User: What is time?
AI: Time is a measurable period during which an action, process, or condition exists or continues.
User: end
AI: Closing the chat. Have a great day!
```
# `countNumWords` function

Function to count the number of words in a text string

```matlab
function numWords = countNumWords(text)
    numWords = doclength(tokenizedDocument(text));
end
```

*Copyright 2023\-2024 The MathWorks, Inc.*

