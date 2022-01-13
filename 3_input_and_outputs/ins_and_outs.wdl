version 1.0

workflow AnalyzeSequencingLibrary {
  input {
    File library_forward_reads
    File library_reverse_reads
    Array[File] sequencing_library
  }
  
  call AnalyzeLibraryPrimitiveTypes {input: library_forward_reads = library_forward_reads, library_reverse_reads = library_reverse_reads}
  call AnalyzeLibraryCompoundType {input: sequencing_library = sequencing_library}

  output {
    File forward_reads_with_locus = AnalyzeLibraryPrimitiveTypes.forward_reads_with_locus
    File reverse_reads_with_locus = AnalyzeLibraryPrimitiveTypes.reverse_reads_with_locus
    File write_lines_forward_reads_with_locus = AnalyzeLibraryCompoundType.write_lines_forward_reads_with_locus
    File write_lines_reverse_reads_with_locus = AnalyzeLibraryCompoundType.write_lines_reverse_reads_with_locus
    File sep_forward_reads_with_locus = AnalyzeLibraryCompoundType.sep_forward_reads_with_locus
    File sep_reverse_reads_with_locus = AnalyzeLibraryCompoundType.sep_reverse_reads_with_locus
  }
}

task AnalyzeLibraryPrimitiveTypes {
  input {
    File library_forward_reads
    File library_reverse_reads
  }

  command {

    # "library_forward_reads" and "library_reverse_reads" are "File" types which is a primitive types
    # Primitive types can be interpreted using "$" + "open_brace closed_brace" where the variable of interest is placed within the braces

    # Define locus of interest
    locus="CAGAAA"

    # Search for locus in forward and reverse reads
    zcat ${library_forward_reads} | grep -B1 -A2 $locus | gzip > forward_reads_with_locus.fastq.gz
    zcat ${library_reverse_reads} | grep -B1 -A2 $locus | gzip > reverse_reads_with_locus.fastq.gz

  }

  runtime {
    memory: "2MB"
  }

  output {
    File forward_reads_with_locus = "forward_reads_with_locus.fastq.gz"
    File reverse_reads_with_locus = "reverse_reads_with_locus.fastq.gz"
  }
}

task AnalyzeLibraryCompoundType {
  input {
    Array[File] sequencing_library
  }

  command {

    # "sequencing_library" is a compound type, specifically it is type: "Array[File]".
    # Compound Types cannot be interpreted directly, they must be "serialized" using a function such as "write_lines()".
    # "write_lines" turns an array into a file, with each element in the array occupying a line in the file.
    # "sep" flattens an array


    # OPTION 1: "write_lines"
    # Define locus of interest
    locus="CAGAAA"

    # Search for locus in forward and reverse reads
    cat ${write_lines(sequencing_library)} | while read forward_or_reverse_reads 
    do
      if [[ "$forward_or_reverse_reads" == *"_R1_"* ]]
      then
        zcat $forward_or_reverse_reads | grep -B1 -A2 $locus | gzip >> write_lines_forward_reads_with_locus.fastq.gz
      else
        zcat $forward_or_reverse_reads | grep -B1 -A2 $locus | gzip >> write_lines_reverse_reads_with_locus.fastq.gz
      fi
    done

    # OPTION 2: "sep"
    forward_reads=$(echo ${sep=' ' sequencing_library} | sed "s/ .*//g")
    reverse_reads=$(echo ${sep=' ' sequencing_library} | sed "s/.* //g")

    zcat $forward_reads | grep -B1 -A2 $locus | gzip >> sep_forward_reads_with_locus.fastq.gz
    zcat $reverse_reads | grep -B1 -A2 $locus | gzip >> sep_reverse_reads_with_locus.fastq.gz
  }

   runtime {
     memory: "2MB"
   }

  output {
    # A task's command can only output data as files. 
    # Therefore, every de-serialization function in WDL takes a file input and returns a WDL type
    File write_lines_forward_reads_with_locus = "write_lines_forward_reads_with_locus.fastq.gz"
    File write_lines_reverse_reads_with_locus = "write_lines_reverse_reads_with_locus.fastq.gz"
    File sep_forward_reads_with_locus = "sep_forward_reads_with_locus.fastq.gz"
    File sep_reverse_reads_with_locus = "sep_reverse_reads_with_locus.fastq.gz"
  }
}
