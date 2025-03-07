#!/bin/bash

# Check if fastq-dump is already installed
if which fastq-dump > /dev/null; then
    echo "fastq-dump is already installed. Skipping download and extraction."
else
    # Download the SRAtoolkit for downloading data
    wget -q --output-document sratoolkit.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.1.0/sratoolkit.3.1.0-ubuntu64.tar.gz
    # Extract the downloaded toolkit
    tar -xzf sratoolkit.tar.gz
    # Add the fastq-dump tool to the PATH (optional, if you want to use it globally)
    export PATH=$PATH:$(pwd)/sratoolkit.3.1.0-ubuntu64/bin
fi
# Run a trial of fastq-dump (fetch 3 reads)
echo "Running a trial of fastq-dump (fetching 3 reads):"
#fastq-dump -X 3 SRR11537950 --stdout
#download  the data
echo "Running a trial of fastq-dump (fetching 1,000,000 reads, splitting files, and gzip compressing):"
#fastq-dump --split-files --gzip -X 1000000 SRR11537950
echo "If we need the full dataset we can just run without X option."

##Format the data for cell ranger pipeline
mkdir -p SRR11537950
mv SRR11537950_1.fastq.gz SRR11537950/SRR11537950_S1_L001_R1_001.fastq.gz
mv SRR11537950_2.fastq.gz SRR11537950/SRR11537950_S1_L001_R2_001.fastq.gz

echo "Lets download Cell Ranger and Ref Fles."
CELLRANGER_URL="https://cf.10xgenomics.com/releases/cell-exp/cellranger-9.0.0.tar.gz?Expires=1738840469&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA&Signature=EqlZ5BgD8-hNglEQXRTKzJOAshgKhwzLxmGyNp4nG3QzCVP7-vB0VAxx1HEn9rn3wISGG3c06r9UwPAtHF9BawhUU7X~bkmzLqPfdNBmdMmprsC~oEbX3o4rrUL3WwCGU1Gc3cOYkHj77Gmyml4jgkBd9ZVE6Az4j-sCJOc~KyIdsqrYHDTAFBUDrYIVba~175s9lEhSEwK0Hio7zl9sCkTpmvr6IKDouLLJgqXuN9bWCgfsUckU2f1znbJI3keNSo6EhOkd-6XIUtlsmx5E0rIKi5qdFjGAGmDmzUVEsykJEdtb1DnVGtsbjCym0TU6KJ4t7MN3x53EzwVob2W3ag__"
CELLRANGER_FILE="cellranger-9.0.0.tar.gz"
REFSEQ_URL="https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2024-A.tar.gz"
REFSEQ_FILE="refdata-gex-GRCh38-2024-A.tar.gz"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "start download!: $TIMESTAMP"
# Download the files if they dont exist.
echo "Checking for $CELLRANGER_FILE..."
wget -nc -O "$CELLRANGER_FILE" "$CELLRANGER_URL"
echo "Checking for $REFSEQ_FILE..."
wget -nc -O "$REFSEQ_FILE" "$REFSEQ_URL"
#extract the files
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "download complete!: $TIMESTAMP"
#tar -xzf "$CELLRANGER_FILE"
#tar -xzf "$REFSEQ_FILE"
cellranger="$PWD/cellranger-9.0.0/bin/cellranger"
human_refseq="$PWD/refdata-gex-GRCh38-2024-A"

# Run cellranger count
echo "Running cellranger count"
# Define parameters for cellranger count
ID="run_count_SRR11537950"
TRANSCRIPTOME="$human_refseq"
FASTQS="SRR11537950"
SAMPLE="SRR11537950"
CHEMISTRY="fiveprime"
LOCAL_CORES=10
LOCAL_MEM=32
# Remove the output directory if it already exists
if [ -d "$ID" ]; then
    echo "Removing existing output directory: $ID..."
    rm -rf "$ID"
fi
# Run cellranger count
$cellranger count \
    --id="$ID" \
    --transcriptome="$TRANSCRIPTOME" \
    --create-bam=true \
    --fastqs="$FASTQS" \
    --sample="$SAMPLE" \
    --chemistry="$CHEMISTRY" \
    --localcores="$LOCAL_CORES" \
    --localmem="$LOCAL_MEM" || { echo "Error: cellranger count failed"; exit 1; }
echo "cellranger count completed: $(date +"%Y-%m-%d %H:%M:%S")"