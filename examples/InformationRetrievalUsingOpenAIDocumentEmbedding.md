
# Information Retrieval Using OpenAI Document Embedding

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/InformationRetrievalUsingOpenAIDocumentEmbedding.mlx](mlx-scripts/InformationRetrievalUsingOpenAIDocumentEmbedding.mlx) 

This example shows how to find documents to answer queries using the 'text\-embedding\-3\-small' document embedding model. Embeddings are used to represent documents and queries in a high\-dimensional space, allowing for the efficient retrieval of relevant information based on semantic similarity. 


The example consists of four steps:

-  Download and preprocess text from several MATLAB® documentation pages. 
-  Embed query document and document corpus using the "text\-embedding\-3\-small" document embedding. 
-  Find the documentation page most relevant to the query using cosine similarity scores. 
-  Generate an answer to the query based on the most relevant documentation page. 

This process is sometimes referred to as Retrieval\-Augmented Generation (RAG), similar to the application found in the example [ExampleRetrievalAugmentedGeneration.mlx](./ExampleRetrievalAugmentedGeneration.mlx).


This example requires Text Analytics Toolbox™. 


To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
```
# Embed Query Document

Convert the query into a numerical vector using the extractOpenAIEmbeddings function. Specify the model as "text\-embedding\-3\-small".

```matlab
query = "What is the best way to store data made up of rows and columns?";
[qEmb, ~] = extractOpenAIEmbeddings(query, ModelName="text-embedding-3-small");
qEmb(1:5)
```

```matlabTextOutput
ans = 1x5
   -0.0051   -0.0005    0.0362   -0.0069    0.0534

```

# Download and Embed Source Text

In this example, we will scrape content from several MATLAB documentation pages. 


This requires the following steps:

1.  Start with a list of websites. This examples uses pages from MATLAB documentation.
2. Extract the context of the pags using `extractHTMLText`.
3. Embed the websites using `extractOpenAIEmbeddings`.
```matlab
metadata = ["https://www.mathworks.com/help/matlab/numeric-types.html";
    "https://www.mathworks.com/help/matlab/characters-and-strings.html";
    "https://www.mathworks.com/help/matlab/date-and-time-operations.html";
    "https://www.mathworks.com/help/matlab/categorical-arrays.html";
    "https://www.mathworks.com/help/matlab/tables.html"];
id = (1:numel(metadata))';
document = strings(numel(metadata),1);
embedding = [];
for ii = id'
    page = webread(metadata(ii));
    tree = htmlTree(page);
    subtree = findElement(tree,"body");
    document(ii) = extractHTMLText(subtree, ExtractionMethod="article");
    try
        [emb, ~] = extractOpenAIEmbeddings(document(ii),ModelName="text-embedding-3-small");
        embedding = [embedding; emb];
    catch
    end
end
vectorTable = table(id,document,metadata,embedding);
```
# Generate Answer to Query

Define the system prompt in `openAIChat` to answer questions based on context.

```matlab
chat = openAIChat("You are a helpful MATLAB assistant. You will get a context for each question");
```

Calculate the cosine similarity scores between the query and each of the documentation page using the `cosineSimilarity` function.  

```matlab
s = cosineSimilarity(vectorTable.embedding,qEmb);
```

Use the most similar documentation content to feed extra context into the prompt for generation.

```matlab
[~,idx] = max(s);
context = vectorTable.document(idx);
prompt = "Context: " ...
    + context + newline + "Answer the following question: " + query;
wrapText(prompt)
```

```matlabTextOutput
ans = 
    "Context: table is a data type suitable for column-oriented or tabular data that is often stored as columns in a text file or in a spreadsheet.
     Tables consist of rows and column-oriented variables.
     Each variable in a table can have a different data type and a different size with the one restriction that each variable must have the same number of rows.
     For more information, see Create Tables and Assign Data to Them or watch Tables and Categorical Arrays.
     Answer the following question: What is the best way to store data made up of rows and columns?"

```


Pass the question and the context for generation to get a contextualized answer.

```matlab
response = generate(chat, prompt);
wrapText(response)
```

```matlabTextOutput
ans = 
    "The best way to store data made up of rows and columns in MATLAB is by using the table data type.
     Tables are designed for storing tabular data, where each column can have a different data type and size, but all columns must have the same number of rows.
     This makes tables an ideal data structure for organizing and manipulating data in a tabular format."

```

# Helper Function

Helper function to wrap text for easier reading in the live script.

```matlab
function wrappedText = wrapText(text)
    wrappedText = splitSentences(text);
    wrappedText = join(wrappedText,newline);
end
```

*Copyright 2024 The MathWorks, Inc.*

