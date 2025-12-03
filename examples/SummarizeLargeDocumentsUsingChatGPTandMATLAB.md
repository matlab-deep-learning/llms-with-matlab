
# Summarize Large Documents Using ChatGPT and MATLAB

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/SummarizeLargeDocumentsUsingChatGPTandMATLAB.mlx](mlx-scripts/SummarizeLargeDocumentsUsingChatGPTandMATLAB.mlx) 

This example shows how to use ChatGPT™ to summarize documents that are too large to be summarized at once.


To summarize short documents using ChatGPT, you can pass the documents directly as a prompt together with an instruction to summarize them. However, ChatGPT can only process prompts of limited size.


To summarize documents that are larger than this limit, split the documents up into smaller documents. Summarize the smaller document chunks, then pass all of the summaries to ChatGPT to generate one overall summary.

-  This example includes four steps: 
-  Download the complete text of "Alice in Wonderland" by Lewis Carroll from Project Gutenberg. 
-  Split the documents up into chunks of less than 3000 words.  
-  Use ChatGPT to create summaries of each chunk. 
-  Then use ChatGPT to create a summary of all of the summaries.  

To run this example, you need Text Analytics Toolbox™.


To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
```
# Download Text Data

Download and read the content from Alice's Adventures in Wonderland by Lewis Carroll from Project Gutenberg.


First read the contents of the webpage using the `webread` function. Specify the time out duration using the `weboptions` function. The HTML header from the source document does not specify the character encoding. To ensure good results independent of your language settings, also specify the character encoding using the `weboptions` function.

```matlab
options = weboptions(Timeout=30,CharacterEncoding="UTF-8");
code = webread("https://www.gutenberg.org/files/11/11-h/11-h.htm", options);
longText = extractHTMLText(string(code));
```
# Split Document Into Chunks

Large language models have a limit in terms of how much text they can accept as input, so if you try to summarize the complete book, you will likely get an error. A workaround is splitting the book into chunks and summarize each chunk individually. The chunk size is defined in `limitChunkWords`, which restricts the numbers of words in a chunk.

```matlab
incrementalSummary = longText;
limitChunkWords = 3000;
chunks = createChunks(incrementalSummary, limitChunkWords);
```
# Summarize Chunks

Initialize a ChatGPT session with the role of summarizing text. This example uses the model GPT\-4.1 nano.

```matlab
summarizer = openAIChat("You are a professional summarizer.", ModelName="gpt-4.1-nano");
```

Looping process to gradually summarize the text chunk by chunk, reducing the chunk size with each iteration. 

```matlab
numCalls = 0;
while numel(chunks)>1
    summarizedChunks = strings(size(chunks));
    numCalls = numCalls + numel(chunks);
```

Add a limit to the number of calls, to ensure you are not making more calls than what is expected. You can change this value to match what is needed for your application.

```matlab
    if numCalls > 20
        error("Document is too long to be summarized.")
    end

    for i = 1:length(chunks)
     summarizedChunks(i) = generate(summarizer, "Summarize this content:" + newline + chunks(i));     
    end 
```

Merge the summarized chunks to serve as the base for the next iteration.

```matlab
    incrementalSummary = join(summarizedChunks);
```

Form new chunks with a reduced size for the subsequent iteration.

```matlab
    chunks = createChunks(incrementalSummary, limitChunkWords);
end
```
# Summarize Document

Compile the final summary by combining the summaries from all the chunks.

```matlab
fullSummary = generate(summarizer, "The following text is a combination of summaries. " + ...
    "Provide a cohese and coherent summary combining these smaller summaries, preserving as much information as possible:" + newline + incrementalSummary);
wrapText(fullSummary)
```

```matlabTextOutput
ans = 
    "The excerpt from Lewis Carroll's "Alice’s Adventures in Wonderland" vividly depicts Alice’s fantastical journey through a surreal and whimsical realm filled with eccentric characters, bizarre settings, and illogical scenarios.
     Initially, Alice adventures down a rabbit-hole while chasing the White Rabbit with a pocket watch, leading her into Wonderland, a land of constant size changes and peculiar encounters.
     She consumes mysterious cakes and potions that cause her to shrink or grow, sometimes making her over nine feet tall and other times too small to fit through doors, exemplifying the whimsical logic of the world.
     Throughout her travels, Alice interacts with a diverse array of characters, including the White Rabbit, a grumpy Caterpillar smoking a hookah who challenges her understanding of identity, the Cheshire Cat offering cryptic advice, the Duchess with her sarcastic banter, and various animals engaged in nonsensical activities.
     She explores strange environments such as a locked hall with a tiny door leading to a beautiful garden, chaotic kitchens, and a garden where roses are painted white.
     Notable scenes include the humorous Caucus-race where everyone wins prizes, Alice helping the White Rabbit find his gloves and fan, and her participation in a mad tea-party hosted by the March Hare and the Hatter, featuring riddles like “Why is a raven like a writing-desk?”
     and conversations about manipulating time and living at the bottom of a treacle well.
     Alice also witnesses the Queen of Hearts’ violent temper during a chaotic game of croquet using live hedgehogs and flamingoes, and observes a courtroom trial over stolen tarts with improbable evidence and absurd proceedings, satirizing judicial processes.
     Throughout her journey, Alice experiences moments of wonder, confusion, frustration, and curiosity.
     She contemplates her identity, questions her surroundings, and navigates the illogical world with a playful sense of imagination.
     The narrative's surreal and humorous tone highlights themes of curiosity, nonsense, authority, and the blurring of reality and imagination, creating a richly satirical and whimsical portrayal of Wonderland’s chaotic, absurd universe."

```

# `createChunks` function

This function segments a long text into smaller parts of a predefined size to facilitate easier summarization. It preserves the structure of sentences. The `chunkSize` should be large enough to fit at least one sentence.

```matlab
function chunks = createChunks(text, chunkSize)
    % Tokenizing the input text for processing
    text = tokenizedDocument(text);
    
    % Splitting the tokenized text into individual sentences
    text = splitSentences(text);
    chunks = [];
    currentChunk = "";
    currentChunkSize = 0;
    
    % Iterating through the sentences to aggregate them into chunks until the chunk 
    % attains the predefined size, after which a new chunk is started
    for i=1:length(text)
        newChunkSize = currentChunkSize + doclength(text(i));
        if newChunkSize < chunkSize
            currentChunkSize = currentChunkSize + doclength(text(i));
            currentChunk = currentChunk + " " + joinWords(text(i));
        else
            chunks = [chunks; currentChunk]; %#ok
            currentChunkSize = doclength(text(i));
            currentChunk = joinWords(text(i));
        end
    end
end
```
# `wrapText` function

This function splits text into sentences and then concatenates them again using `newline` to make it easier to visualize text in this example

```matlab
function wrappedText = wrapText(text)
wrappedText = splitSentences(text);
wrappedText = join(wrappedText,newline);
end
```

*Copyright 2023 The MathWorks, Inc.*

