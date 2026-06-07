# Simple Benchmark

| tool           | input | real  | user  | sys  | rate        | ratio  |
|:--------------:|:-----:|:-----:|:-----:|:----:|:-----------:|:------:|
| wc -l          | dd    | 16.1  | 15.8  | 3.6  | 1,018 MiB/s | (100%) |
| wazero w/ simd | dd    |  4.6  |  3.9  | 8.3  | 3,562 MiB/s |  350%  |
| wc -l          | wikix |  1.12 |  1.10 | 0.23 | 22M lines/s | (100%) |
| wazero w/ simd | wikix |  0.27 |  0.24 | 0.45 | 92M lines/s |  400%  |

wikix: enwiki-20250801-pages-articles-multistream-index.txt
