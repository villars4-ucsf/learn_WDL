version 1.0

workflow BinReadsWithCutAdapt {
  input {
    Array[File] sequencing_library
    Array[File] primer_set
  }
  
  call BinByAmplicon {input: sequencing_library = sequencing_library, primer_set = primer_set}

  output {
    File binned_forward_seqs = BinByAmplicon.binned_forward_seqs
    File binned_reverse_seqs = BinByAmplicon.binned_reverse_seqs
    File log = BinByAmplicon.log
  }
}

task BinByAmplicon {
  input {
    Array[File] sequencing_library
    Array[File] primer_set
    }

  command {

    : '
      NOTE
        a. -j flag sets num cores
        b. primer seqs have caret in order to force primer search at begining of read
        c. primers need to be removed from reads bc the error
           profile of the primers skews the dada2 algorithm
    '

    # Save path to file containing path to primers
    primer_files=${write_lines(primer_set)}
    forward_primer=$(sed -n '1p' $primer_files) # save first line of "write_lines" file as forward primer
    reverse_primer=$(sed -n '2p' $primer_files) # save second line of "write_lines" file as reverse primer

    # Save path to file containing path to sequences
    sequencing_files=${write_lines(sequencing_library)} 
    forward_reads=$(sed -n '1p' $sequencing_files) # save first line of "write_lines" file as forward reads
    reverse_reads=$(sed -n '2p' $sequencing_files) # save first line of "write_lines" file as forward reads

    # Removing Primers
    cutadapt \
      --action=retain \
      --discard-untrimmed \
      -g file:$forward_primer \
      -G file:$reverse_primer \
      --pair-adapters \
      -o binned_R1.fastq.gz \
      -p binned_R2.fastq.gz \
      -e 0 \
      --no-indels \
      $forward_reads \
      $reverse_reads > cutadapt.log

  }

   runtime {
     simg: "/wynton/home/rodriguez-barraquer/villars4_ucsf/library/singularity/cutadapt-3.5.sif"
     memory: "2 MB"
   }

  output {
    File binned_forward_seqs = "binned_R1.fastq.gz"
    File binned_reverse_seqs = "binned_R2.fastq.gz"
    File log = "cutadapt.log"
  }

}
