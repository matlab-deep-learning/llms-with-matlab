
# Create Simple ChatBot

To run the code shown on this page, open the MLX file in MATLAB: [mlx-scripts/CreateSimpleOllamaChatBot.mlx](mlx-scripts/CreateSimpleOllamaChatBot.mlx) 

This example shows how to create a simple chatbot using the `ollamaChat` and `messageHistory` functions.


When you run this example, an interactive AI chat starts in the MATLAB® Command Window. To leave the chat, type "end" or press **Ctrl+C**.

-  This example includes three steps: 
-  Define model parameters, such as the maximum word count, and a stop word. 
-  Create an ollamaChat object and set up a meta prompt. 
-  Set up the chat loop. 

To run this example, you need a running Ollama™ installation. To run it unchanged, you need to have Mistral® pulled into that Ollama server.

```matlab
loadenv(".env")
addpath('../..')
```
# Setup Model

Set the maximum allowable number of words per chat session and define the keyword that, when entered by the user, ends the chat session.

```matlab
wordLimit = 2000;
stopWord = "end";
```

Create an instance of `ollamaChat` to perform the chat and `messageHistory` to store the conversation history`.`

```matlab
chat = ollamaChat("mistral");
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
    dispWrapped("User", query)
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
        error("Your query should have fewer than " + wordLimit + " words. You query had " + numWordsQuery + " words.")
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
    
    dispWrapped("AI", text)
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
User: Please help me with creating a Butterworth bandpass filter in MATLAB.
AI: Sure, I can help you create a Butterworth bandpass filter in MATLAB. 
    Here's an example of how you can do it:
    
1. First, we need to define the low-pass and high-pass cutoff
    frequencies for our bandpass filter. Let's say we want a bandpass 
    filter with a lower cutoff frequency of 0.5 Hz and an upper cutoff 
    frequency of 2 Hz.
    
    ```matlab
    lowcut = 0.5; % Lower cutoff frequency (in Hertz)
    highcut = 2; % Upper cutoff frequency (in Hertz)
    ```
    
    2. Next, we define the order of the filter. The order determines how 
    steep the transition between pass and stop bands will be. A higher 
    order means a steeper roll-off but may also introduce more phase 
    distortion. For this example, let's use an order of 5.
    
    ```matlab
    order = 5; % Order of the filter
    ```
    
    3. Now we can create the bandpass Butterworth filter using the 
    `butter()` function in MATLAB. This function takes three arguments: 
    the normalized frequencies (in rad/sec), an 's' vector for the 
    low-pass and high-pass filters, and the order of the filter.
    
    ```matlab
    [num, den] = butter(order, [lowcut/samplingFrequency, 1 - 
    lowcut/highcut, highcut/samplingFrequency]);
    ```
    
    In this line, `samplingFrequency` should be replaced with the 
    sampling frequency of your data. For example, if you are working with 
    data sampled at 100 Hz, you would set `samplingFrequency = 100;`.
    
    4. Finally, you can apply the filter to a signal using the `filter()` 
    function in MATLAB.
    
    ```matlab
    filteredSignal = filter(num, den, inputSignal);
    ```
    
    Replace `inputSignal` with your actual input data.
    
    This should give you a bandpass-filtered version of your signal. You 
    can adjust the cutoff frequencies and the order of the filter to best 
    suit your specific needs.
User: I would like the frequency range to be 144-146 MHz, assuming a sample 
      rate of 2MS/s.
AI: In that case, here is how you could define the cutoff frequencies:
    
    ```matlab
    lowcut = (144e6)/(2e6); % Lower cutoff frequency (in rad/sec)
    highcut = (146e6)/(2e6); % Upper cutoff frequency (in rad/sec)
    ```
    
    Now you can proceed with the filter creation as described in my 
    previous response. Make sure to replace `samplingFrequency` with the 
    actual sample rate of your data, which in this case is 2e6 Hz.
    
    ```matlab
    [num, den] = butter(order, [lowcut, 1 - lowcut/(highcut), highcut]);
    ```
User: How do I export the parameters to use in GNU Radio?
AI: To export the Butterworth filter coefficients from MATLAB and use 
    them in GNU Radio, you can save the numerator and denominator 
    coefficients as separate text files. Here's how:
    
1. Save the numerator coefficients:
    
    ```matlab
    filename_num = 'numerator_coefficients.txt';
    fid_num = fopen(filename_num, 'w');
    for i = 1 : length(num)
        fprintf(fid_num, '%g\n', num(i));
    end
    fclose(fid_num);
    ```
    
    2. Save the denominator coefficients:
    
    ```matlab
    filename_den = 'denominator_coefficients.txt';
    fid_den = fopen(filename_den, 'w');
    for i = 1 : length(den)
        fprintf(fid_den, '%g\n', den(i));
    end
    fclose(fid_den);
    ```
    
    Now you have two text files with the numerator and denominator 
    coefficients. You can import these coefficient lists in GNU Radio 
    using Polyphase FIR Filter blocks or any other filter blocks that 
    allow specifying taps directly. In the GNU Radio GUI, you'll need to 
    set the number of taps based on the length of the coefficient lists 
    loaded from the text files.
User: end
AI: Closing the chat. Have a great day!
```
# `Helper Functions`

Function to count the number of words in a text string

```matlab
function numWords = countNumWords(text)
    numWords = doclength(tokenizedDocument(text));
end
```

Function to display wrapped text, with hanging indentation from a prefix

```matlab
function dispWrapped(prefix, text)
    indent = [newline, repmat(' ',1,strlength(prefix)+2)];
    text = strtrim(text);
    disp(prefix + ": " + join(textwrap(text, 70),indent))
end
```

*Copyright 2023\-2024 The MathWorks, Inc.*

