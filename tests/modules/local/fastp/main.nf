nextflow_process {

    name "Test Process FASTP"
    script "modules/local/fastp/main.nf"
    process "FASTP"

    test("Should run without failures") {

        when {
            params {
                outdir = "$outputDir"
            }
            process {
                """
                input[0] = [[id:"dummy"], [file("test_data/read1.fastq.gz"), file("test_data/read2.fastq.gz")]]
                input[1] = false
                input[2] = false
                """
            }
        }

        then {
            assert process.success
            with(process.out) {
                assert json.ssize() == 1
                def json_path = json.get(0)[1]
                def info = path(json_path).json
                assert info.summary.after_filtering.total_reads == 44
            }
        }

    }

}
