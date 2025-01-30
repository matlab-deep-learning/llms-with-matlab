
# Retrieval\-Augmented Generation Using Ollama™ and MATLAB

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/RetrievalAugmentedGenerationUsingOllamaAndMATLAB.mlx](mlx-scripts/RetrievalAugmentedGenerationUsingOllamaAndMATLAB.mlx) 

This example shows how to use retrieval\-augmented generation to generate answers to queries based on information contained in a document corpus. 


The example contains three steps:

-  Download and preprocess documents. 
-  Find documents relevant to a query using keyword search. 
-  Generate a response using Ollama based on the both the query and the most relevant source document. 

This example requires Text Analytics Toolbox™ and a running Ollama service. As written, it requires the Mistral® NeMo model to be installed in that Ollama instance.

# Download and Preprocess Documents

Specify the URLs of the reports.

```matlab
url = ["https://openknowledge.worldbank.org/bitstreams/0c18c872-91f0-51a4-ba91-c36b98893b4a/download"
    "https://openknowledge.worldbank.org/bitstreams/476f037b-a17e-484f-9cc2-282a2e5a929f/download"
    "https://openknowledge.worldbank.org/bitstreams/0c18c872-91f0-51a4-ba91-c36b98893b4a/download"];
```

Define the local path where the reports will be saved and download the reports using the provided URLs and save them to the specified local path.

```matlab
localpath = "./data/";
if ~exist(localpath, "dir")
    mkdir(localpath);
end
numFiles = numel(url);
for i = 1:numFiles
    filename = "WBD_" + i + ".pdf";
    localFileName = fullfile(localpath, filename);
    if ~exist(localFileName,"file")
        websave(localFileName, url{i}, weboptions(Timeout=30));
    end
end
```

Define the function to read the text from the downloaded files.

```matlab
readFcn = @extractFileText;
filePattern = [".txt",".pdf",".docx",".html",".htm"];
fds = fileDatastore(localpath,'FileExtensions',filePattern,'ReadFcn',readFcn);

str = readall(fds);
str = [str{:}];
```

Split the text data into paragraphs with the helper function `preprocessDocuments`.

```matlab
documents = preprocessDocuments(str);
```

Initialize the chatbot with the model name (Mistral NeMo) and a generic system prompt. Due to the long input created below, responses may take a long time on older machines; increase the accepted timeout.

```matlab
chat = ollamaChat("mistral-nemo", ...
    "You are a helpful assistant. You will get a " + ...
    "context for each question, but only use the information " + ...
    "in the context if that makes sense to answer the question. " + ...
    "Let's think step-by-step, explaining how you reached the answer.", ...
    TimeOut=600);
```
# Retrieve Relevant Documents

Define the query, then retrieve and filter the relevant documents based on the query.

```matlab
query = "What technical criteria can be used to streamline new approvals for grid-friendly DPV?";
```

Tokenize the query and find similarity scores between the query and documents.

```matlab
embQuery = bm25Similarity(documents, tokenizedDocument(query));
```

Sort the documents in descending order of similarity scores.

```matlab
[~, idx] = sort(embQuery, "descend");
limitWords = 1000;
selectedDocs = [];
totalWords = 0;
```

Iterate over sorted document indices until word limit is reached

```matlab
i = 1;
while totalWords <= limitWords && i <= length(idx)
    totalWords = totalWords + doclength(documents(idx(i)));
    selectedDocs = [selectedDocs; joinWords(documents(idx(i)))];
    i = i + 1;
end
```
# Generate Response

Define the prompt for the chatbot and generate a response.

```matlab
prompt = "Context:" + join(selectedDocs, " ") + newline + ...
    "Answer the following question: " + query;
response = generate(chat, prompt);
```

Wrap the text for easier visualization.

```matlab
wrapText(response)
```

```matlabTextOutput
ans = 
    "Based on the provided context, several technical criteria can be used to 
     streamline new approvals for grid-friendly DPV (Distributed Photovoltaics). 
     These include:
     
1. **Inverter Programming:** Ensuring inverters have appropriate programming to
     provide valuable services such as reactive power control for voltage management 
     or active power curtailment for congestion management.
     2. **Capacity Building:** Timely capacity building of personnel to manage high 
     shares of DPV is crucial. This includes training staff on grid integration, 
     operation, and maintenance issues related to DPV.
     3. **Grid Code Adherence:** Adhering to a grid code that reflects expected 
     future growth of distributed energy resources. This ensures technical rules 
     keep pace with installed DPV capacity.
     4. **Prudent Screening Criteria:** Using prudent screening criteria for systems 
     that meet certain specifications. For example, metrics like DPV capacity 
     penetration relative to minimum feeder daytime load can be considered.
     
     By applying these criteria and using case-by-case appraisal, new approvals for 
     grid-friendly DPV installations can potentially be streamlined while 
     maintaining grid reliability and stability."

```
# Helper Functions
```matlab
function allDocs = preprocessDocuments(str)
tokenized = tokenizedDocument(join(str,[newline newline]));
allDocs = splitParagraphs(tokenized);
end

function wrappedText = wrapText(text)
s = textwrap(text,80);
wrappedText = string(join(s,newline));
end
```
# References

*Energy Sector Management Assistance Program (ESMAP). 2023. From Sun to Roof to Grid: Power Systems and Distributed PV. Technical Report. Washington, DC: World Bank. License: Creative Commons Attribution CC BY 3.0 IGO*


*Copyright 2024 The MathWorks, Inc.*

