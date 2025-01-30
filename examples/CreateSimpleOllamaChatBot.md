
# Create Simple ChatBot

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/CreateSimpleOllamaChatBot.mlx](mlx-scripts/CreateSimpleOllamaChatBot.mlx) 

This example shows how to create a simple chatbot using the `ollamaChat` and `messageHistory` functions.


When you run this example, an interactive AI chat starts in the MATLAB® Command Window. To leave the chat, type “end” or press **Ctrl+C**.

-  This example includes three steps: 
-  Define model parameters, such as the maximum word count, and a stop word. 
-  Create an ollamaChat object and set up a meta prompt. 
-  Set up the chat loop. 

To run this example, you need a running Ollama™ installation. To run it unchanged, you need to have Mistral® NeMo pulled into that Ollama server.

# Setup Model

Set the maximum number of words per chat session. To enable the user to end the chat early, define a stop word.

```matlab
wordLimit = 2000;
stopWord = "end";
```

Create an instance of `ollamaChat` to perform the chat and `messageHistory` to store the conversation history.

```matlab
chat = ollamaChat("mistral-nemo");
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
AI: To create a Butterworth bandpass filter in MATLAB, you'll first need 
    to determine the passband and stopband frequencies, as well as the 
    desired ripple (passband) and attenuation (stopband). Here's a 
    step-by-step guide:
    
1. **Define your filter parameters:**
    
    Assume we want a bandpass filter with:
    - Passband edge frequencies: `Wp = [fL fH]` where `fL` is the 
    low-frequency cutoff and `fH` is the high-frequency cutoff.
    - Stopband edge frequencies: `Ws = [f1 f2]` where `f1` and `f2` are 
    the stopbands close to `fL` and `fH`, respectively (usually 5% higher 
    than the passband edges).
    - Desired ripple (passband): `Rp`
    - Desired attenuation (stopband): `Rs`
    
    For this example, let's choose:
    - Sampling frequency (`Fs`) = 44.1 kHz
    - Passband frequencies (`fL`, `fH`) = [200 Hz, 3000 Hz]
    - Stopband frequencies (`f1`, `f2`) = [`fL*1.05`, `fH*1.05`]
    - Ripple (`Rp`) = 1 dB
    - Attenuation (`Rs`) = 60 dB
    
    ```matlab
    Fs = 44100;      % Sampling frequency (Hz)
    Wp = [200 3000]; % Passband frequencies (Hz)
    Ws = Wp * 1.05;  % Stopband frequencies (Hz)
    Rp = 1;          % Ripple (dB)
    Rs = 60;         % Attenuation (dB)
    ```
    
    2. **Calculate the filter order (`N`):**
    
    To calculate the required filter order (`N`), you can use the 
    `shermanwin`s function:
    
    ```matlab
    [Ns, Np] = shermanwin(Ws/Ws(end), Wp/Wp(end), Rp, Rs);
    N = ceil((Ns + Np) / 2); % Choose an even order for a Butterworth 
    filter
    ```
    
    3. **Design the bandpass filter:**
    
    Now you can design the butterworth filter using the `butter` 
    function:
    
    ```matlab
    [N, Wc] = buttord(Wp/Fs, Ws/Fs, Rp, Rs);
    [b, a] = butter(N, Wc, 'bandpass');
    ```
    
    4. **Plot the filter response:**
    
    You can plot the frequency response using the `freqz` function:
    
    ```matlab
    [H, W] = freqz(b, a, 2048, Fs); % Compute frequency response
    
    % Plot frequency response (amplitude)
    figure;
    plot(W / pi * Fs/2, abs(H));
    grid on;
    title('Bandpass Filter Frequency Response');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    ylim([-120 5]);
    
    % Plot frequency response (phase)
    subplot(2, 1, 2);
    plot(W / pi * Fs/2, unwrap(angle(H)));
    grid on;
    title('Bandpass Filter Phase Response');
    xlabel('Frequency (Hz)');
    ylabel('Phase (rad)');
    ```
    
    5. **Apply the filter to input signals:**
    
    Now you can apply this filter (`b`, `a`) to your input signals using 
    the `filter` function:
    
    ```matlab
    x = your_input_signal;
    y = filter(b, a, x);
    ```
User: I would like the frequency range to be 144-146 MHz, assuming a sample 
      rate of 2MS/s.
AI: To create a Butterworth bandpass filter for an input signal with a 
    sample rate (`Fs`) of 2 MS/s and a desired passband between 144 MHz 
    and 146 MHz, follow these steps:
    
1. **Define your filter parameters:**
    
    ```matlab
    Fs = 2e6;      % Sampling frequency (Hz)
    Wp = [144e6 146e6]; % Passband frequencies (Hz)
    Ws = Wp * 1.05;    % Stopband frequencies (Hz)
    Rp = 1;          % Ripple (dB)
    Rs = 60;         % Attenuation (dB)
    ```
    
    2. **Calculate the filter order (`N`):**
    
    ```matlab
    [Ns, Np] = shermanwin(Ws/Ws(end), Wp/Wp(end), Rp, Rs);
    N = ceil((Ns + Np) / 2); % Choose an even order for a Butterworth 
    filter
    ```
    
    3. **Design the bandpass filter:**
    
    ```matlab
    [N, Wc] = buttord(Wp/Fs, Ws/Fs, Rp, Rs);
    [b, a] = butter(N, Wc, 'bandpass');
    ```
    
    4. **Plot the filter response:**
    
    ```matlab
    [H, W] = freqz(b, a, 2048, Fs); % Compute frequency response
    
    % Plot frequency response (amplitude)
    figure;
    plot(W / pi * Fs/2, abs(H));
    grid on;
    title('Bandpass Filter Frequency Response');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    ylim([-120 5]);
    
    % Plot frequency response (phase)
    subplot(2, 1, 2);
    plot(W / pi * Fs/2, unwrap(angle(H)));
    grid on;
    title('Bandpass Filter Phase Response');
    xlabel('Frequency (Hz)');
    ylabel('Phase (rad)');
    ```
    
    5. **Apply the filter to input signals:**
    
    You can now apply this filter (`b`, `a`) to your input signals using 
    the `filter` function:
    
    ```matlab
    x = your_input_signal;
    y = filter(b, a, x);
    ```
    
    To visualize the passband and stopband frequencies on the plot, you 
    can add vertical lines at these frequencies:
    
    ```matlab
    hold on;
    yline(Wp/Fs * Fs/2, 'r--');
    yline([Ws(1) Ws(end)]/Fs * Fs/2, 'b:');
    legend('Magnitude Response', 'Passband Edges', 'Stopband Edges');
    hold off;
    ```
    
    In this case, the filter will attenuate frequencies below 140.8 MHz 
    and above 156 MHz (Ws*1.05), while passing frequencies between 142.3 
    MHz (`Wp`) with minimal ripple.
    
    Adjust the `Rp` and `Rs` values if you want a different ripple or 
    attenuation performance for your specific application.
User: How do I export the parameters to use in GNU Radio?
AI: To use the designed filter coefficients (`b`, `a`) in GnuRadio 
    Companion (GRC), you'll need to follow these steps:
    
1. **Export filter coefficients:**
    
    MATLAB doesn't have a built-in function to save the filter 
    coefficients for GnuRadio directly, so we'll save them as 
    comma-separated values (.csv) files.
    
    ```matlab
    % Savefilter coefficients
    dlmwrite('b.csv', b');
    dlmwrite('a.csv', a');
    ```
    
    2. **Create a new block in Gnu Radio Companion:**
    
    Open GnuRadio Companion (grc), and drag & drop a "Filter - Filter 
    Design" block from the Analog Blocks section into your main canvas.
    
    3. **Configure the Filter Design block:**
    
    Double-click on the Filter Design block to open its properties 
    window:
    
    - Set `Filter Type` to `FIR Decimating`.
    - Set `Design Method` to `Window`.
    - Set `Order` to the same value you calculated in MATLAB (`N`). Make 
    sure it's even.
    - Set `Transition Width` and `Passband Ripple` according to your 
    desired filter characteristics (you can use the same values as in 
    MATLAB).
    - Click on the `CSV...` button next to the `Numerator Coefficients` 
    field, and load the previously saved `b.csv` file.
    - Click on the `CSV...` button next to the `Denominator Coefficients` 
    field, and load the previously saved `a.csv` file.
    
    4. **Connect input/output signals:**
    
    You can now connect your desired input signal(s) to the Filter Design 
    block's input port (`in`) and add any additional blocks (e.g., 
    Throttle, Source, etc.) as needed before connecting them to the 
    filter block's input port(s).
    
    After configuring your diagram, you can generate Python code using 
    "File" -> "Generate Python", which you can use with Gnu Radio running 
    from the command line:
    
    ```bash
    grc gnu-radio-application.py
    ```
    
    This way, you can apply your designed filter in GnuRadio Companion 
    using the export parameters (`b`, `a`) generated from MATLAB.
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

*Copyright 2023\-2025 The MathWorks, Inc.*

