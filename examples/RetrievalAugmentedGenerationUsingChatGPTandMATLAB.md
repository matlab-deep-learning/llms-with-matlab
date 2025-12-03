
# Retrieval\-Augmented Generation Using ChatGPT and MATLAB

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/RetrievalAugmentedGenerationUsingChatGPTandMATLAB.mlx](mlx-scripts/RetrievalAugmentedGenerationUsingChatGPTandMATLAB.mlx) 

This example shows how to use retrieval\-augmented generation to generate answers to queries based on information contained in a document corpus. 


The example contains three steps:

-  Download and preprocess documents. 
-  Find documents relevant to a query using keyword search. 
-  Generate a response using ChatGPT™ based on the both the query and the most relevant source document. 

This example requires Text Analytics Toolbox™. 


To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
```
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
    local_file_name = fullfile(localpath, filename);
    if ~exist(local_file_name,"file")
        websave(local_file_name, url{i}, weboptions(Timeout=30));
    end
end
```

Define the function to read the text from the downloaded files.

```matlab
readFcn = @extractFileText;
file_pattern = [".txt",".pdf",".docx",".html",".htm"];
fds = fileDatastore(localpath,'FileExtensions',file_pattern,'ReadFcn',readFcn);

str = readall(fds);
str = [str{:}];
```

Split the text data into paragraphs with the helper function `preprocessDocuments`.

```matlab
documents = preprocessDocuments(str);
```

Initialize the chatbot with a system prompt and API key. Include your API key in the environment variable `OPENAI_API_KEY` or pass your key using the `APIKey` name\-value pair. This example uses the model GPT\-4.1 mini.

```matlab
chat = openAIChat("You are a helpful assistant. You will get a " + ...
    "context for each question, but only use the information " + ...
    "in the context if that makes sense to answer the question. " + ...
    "Let's think step-by-step, explaining how you reached the answer.", ...
    ModelName="gpt-4.1-mini");
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
    "To streamline new approvals for grid-friendly distributed photovoltaics (DPV), 
     prudent technical criteria can be applied that balance deployment with the 
     technical requirements of the distribution system. Specifically:
     
1. **Technical Screening Criteria**: Utilities can use technical screening
     criteria based on metrics relevant to the impact of DPV on low-voltage 
     distribution grids. For example, limiting DPV capacity relative to the minimum 
     feeder daytime load helps prevent technical issues.
     
     2. **Hosting Capacity Calculations**: These calculations estimate the point at 
     which DPV penetration would induce technical impacts on system operation. 
     Screening criteria derived from these calculations allow utilities to set 
     limits that ensure grid stability.
     
     3. **Connection Size Limits**: Some regulations specify maximum DPV 
     installation sizes relative to customer peak load (e.g., 80 percent of peak 
     load in India), serving as a straightforward technical criterion for approval.
     
     4. **Advanced Inverter Functions**: Specifying that inverters have advanced 
     capabilities such as reactive power control and active power curtailment before 
     connection approval helps maintain grid stability and voltage management.
     
     5. **Grid Codes Reflecting DPV Growth**: Adopting or updating grid codes to 
     include expected growth of distributed energy resources and requirements for 
     inverter functionalities streamlines approvals by setting clear technical 
     standards.
     
     6. **Cost-effective and Forward-looking Measures**: The criteria should be easy 
     to implement, cost-efficient, and anticipate future system integration needs, 
     helping avoid costly retrofits.
     
     Thus, prudent technical criteria include setting size limits relative to load, 
     applying hosting capacity-based screens, requiring advanced inverter 
     functionalities, and updating grid codes to reflect DPV penetration—all 
     facilitating streamlined, grid-friendly DPV approvals."

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

