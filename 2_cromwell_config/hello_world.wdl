workflow myWorkflow {
    call myTask
}

task myTask {
    command {
        echo "hello world"
    }
    output {
        String out = read_string(stdout())
    }
    runtime {
        memory: "2GB"
    }
}
