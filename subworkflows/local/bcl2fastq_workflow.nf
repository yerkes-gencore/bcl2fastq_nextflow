workflow extractions {
    main:
        // snapshot run params
        runtime_snapshot(workflow.configFiles.toSet().last(), params.run_dir)
        // Find samplesheets
        if (params.sample_sheets.isEmpty()) {
            Channel.fromPath("${params.run_dir}/*[Dd][Ee][Mm][Uu][Xx]*.csv", type: 'file')
                .set{ sample_sheets }
            println 'No sample sheets explicitly provided, using the following sheets found in the directory'
            sample_sheets | view()
        } else {
            Channel.fromList(params.sample_sheets.keySet())
                .set{ sample_sheets }
        }
        // print out params being used
        check_params(params.run_dir, sample_sheets, params.barcode_mismatches) | view()
        // Wait for RTA complete
        check_RTAComplete()
        // Run bcl2fastq
        bcl2fastq(check_RTAComplete.out, params.run_dir, sample_sheets, params.barcode_mismatches)
        // Parse output
        xml_parse(bcl2fastq.out.label, bcl2fastq.out.output_dir)
        if (params.emails?.trim()){
            mail_extraction_complete(xml_parse.out.label, xml_parse.out.demux_file_path)
        }
        // compute md5sums in actual folder, don't rely on copied data being similar 
        if (params.compute_md5sums) {
            md5checksums(bcl2fastq.out.label.collect())
        }
    emit:
        bcl2fastq.out.output_dir
}