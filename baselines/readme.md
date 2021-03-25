### BERT-based baselines

Results obtained from majority voting of 5 [BERTje](https://huggingface.co/GroNLP/bert-base-dutch-cased), [RobBert](https://huggingface.co/pdelobelle/robbert-v2-dutch-base) and [mBERT](https://huggingface.co/bert-base-multilingual-cased) models,
finetuned for 10 epochs, performing model selection based on TRIAL data accuracy.

The **format** is:

| Column 1       | Column 2     | Column 3     |
| :------------- | :----------: | -----------: |
|  pair_id | predicted_label   | true_label   |

where 0 is *contradiction*, 1 is *neutral* and 2 is *entailment*.

