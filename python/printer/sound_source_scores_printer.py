import sys
from dataclasses import dataclass

import pandas as pd

sys.path.append(".")

from python.analyzer.analyze import (  # noqa
    MUSIC_PIECES_LENGTH,
    SOUND_SOURCE_LENGTH,
    get_scores_with_average,
)

COLUMNS = ["GA" + str(i + 1) for i in range(SOUND_SOURCE_LENGTH)] + ["Average"]
COLUMNS_JA = ["A", "B", "C", "D", "平均"]


@dataclass
class __DataSource:
    paths: list[str]
    index: list[str]
    columns: list[str]


method = __DataSource(
    paths=[
        "test/outputs/cross_validations/NCSP_paper/methods/search_tree_0.55_threshold_4_notes__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__select_by_db.csv",
        "test/outputs/cross_validations/NCSP_paper/methods/mean_matching_cosine_similarity_none_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/methods/mean_matching_cosine_similarity_harmonic_0.6-4_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/methods/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
    ],
    index=["Search Tree", "Matching", "Matching-4", "Matching-6"],
    columns=COLUMNS,
)

method_ja = __DataSource(
    paths=[
        "test/outputs/cross_validations/NCSP_paper/methods/search_tree_0.55_threshold_4_notes__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__select_by_db.csv",
        "test/outputs/cross_validations/NCSP_paper/methods/mean_matching_cosine_similarity_none_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/methods/mean_matching_cosine_similarity_harmonic_0.6-4_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/methods/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
    ],
    index=["Search Tree", "Matching", "Matching-4", "Matching-6"],
    columns=COLUMNS_JA,
)

pcp_log_amp = __DataSource(
    paths=[
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__et-scale_sparse_non_reassign_frequency_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__sparse_mags_ln_scaled_override_by_8192__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__et-scale_sparse_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
    ],
    index=["Comb", "ET-scale", "Comb*", "ET-scale*"],
    columns=COLUMNS,
)

pcp = __DataSource(
    paths=[
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__stft_mags_none_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__et-scale_sparse_non_reassign_frequency_none_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__sparse_mags_none_scaled_override_by_8192__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__et-scale_sparse_none_scaled__E2-D#6__minor_flat_five_priority.csv",
    ],
    index=["Comb", "ET-scale", "Comb*", "ET-scale*"],
    columns=COLUMNS,
)


pcp_log_amp_ja = __DataSource(
    paths=[
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__et-scale_sparse_non_reassign_frequency_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__sparse_mags_ln_scaled_override_by_8192__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__et-scale_sparse_ln_scaled__E2-D#6__minor_flat_five_priority.csv",
    ],
    index=["コムフィルタ", "平均律ビン", "コムフィルタ*", "平均律ビン*"],
    columns=COLUMNS_JA,
)

pcp_ja = __DataSource(
    paths=[
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__stft_mags_none_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__et-scale_sparse_non_reassign_frequency_none_scaled__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__sparse_mags_none_scaled_override_by_8192__E2-D#6__minor_flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__et-scale_sparse_none_scaled__E2-D#6__minor_flat_five_priority.csv",
    ],
    index=["コムフィルタ", "平均律ビン", "コムフィルタ*", "平均律ビン*"],
    columns=COLUMNS_JA,
)


def __print(source: __DataSource) -> None:
    scores_table = [
        get_scores_with_average(
            pd.read_csv(
                path,
                dtype=str,
                skiprows=1,
                header=None,
            )
        )
        for path in source.paths
    ]
    df = pd.DataFrame(
        scores_table,
        index=source.index,
        columns=source.columns,
    )
    print(
        df.to_latex(
            column_format="lccccc",
            float_format=lambda x: f"{x*100:.1f}",
        )
    )


if __name__ == "__main__":
    # __print(method)
    # __print(method_ja)
    # __print(pcp_log_amp)
    # __print(pcp)
    __print(pcp_log_amp_ja)
    __print(pcp_ja)
