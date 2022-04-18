include { GUNZIP as GUNZIP_FASTA            } from '../../modules/nf-core/modules/gunzip/main'
include { UNTAR as UNTAR_BWA_INDEX          } from '../../modules/nf-core/modules/untar/main'
include { PICARD_CREATESEQUENCEDICTIONARY   } from '../../modules/nf-core/modules/picard/createsequencedictionary/main'
include { BWA_INDEX                         } from '../../modules/nf-core/modules/bwa/index/main'
include { SAMTOOLS_FAIDX                    } from '../../modules/nf-core/modules/samtools/faidx/main'

workflow PREPARE_GENOME {
    take:
    prepare_tool_indices

    main:
    ch_versions = Channel.empty()
    if (params.fasta.endsWith('.gz')) {
        ch_fasta    = GUNZIP_FASTA ( [ [:], params.fasta ] ).gunzip.map { it[1] }
        ch_versions = ch_versions.mix(GUNZIP_FASTA.out.versions)
    } else {
        ch_fasta = file(params.fasta)
    }

    // Uncompress bwa index or generate from scratch if required
    ch_bwa_index = Channel.empty()
    if ('bwa' in prepare_tool_indices) {
        if (params.bwa_index) {
            if (params.bwa_index.endsWith('.tar.gz')) {
                ch_bwa_index = UNTAR_BWA_INDEX ( params.bwa_index ).untar
                ch_versions = ch_versions.mix(UNTAR_BWA_INDEX.out.versions)
            } else {
                ch_bwa_index = file(params.bwa_index)
            }
        } else {
            ch_bwa_index = BWA_INDEX ( ch_fasta ).index
            ch_versions = ch_versions.mix(BWA_INDEX.out.versions)
        }
    }

    ch_dict_index = Channel.empty()
    if ('dict' in prepare_tool_indices) {
        if (params.dict_index) {
            ch_dict_index = file(params.dict_index)
        } else {
            Channel.from(ch_fasta)
            | map { [[id:it.baseName], it]}
            | PICARD_CREATESEQUENCEDICTIONARY
            ch_dict_index = PICARD_CREATESEQUENCEDICTIONARY.out.reference_dict
            ch_versions = ch_versions.mix(PICARD_CREATESEQUENCEDICTIONARY.out.versions)
        }
    }

    ch_fai_index = Channel.empty()
    if ('fai' in prepare_tool_indices) {
        if (params.fai_index) {
            ch_fai_index = file(params.fai_index)
        } else {
            Channel.from(ch_fasta)
            | map { [[id:it.baseName], it]}
            | SAMTOOLS_FAIDX
            ch_fai_index = SAMTOOLS_FAIDX.out.fai
            ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)
        }
    }

    emit:
    fasta      = ch_fasta                                         //    path: genome.fasta
    fai        = ch_fai_index.map  { meta, path -> path }.first() //    path: genome.fasta.fai
    dict       = ch_dict_index.map { meta, path -> path }.first() //    path: genome.fasta.dict
    bwa_index  = ch_bwa_index                                     //    path: bwa/index/
    // -- //
    versions = ch_versions.ifEmpty(null)                  // channel: [ versions.yml ]
}