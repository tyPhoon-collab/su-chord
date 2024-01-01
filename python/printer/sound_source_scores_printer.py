import sys

import pandas as pd

sys.path.append(".")

from python.analyzer.analyze import (  # noqa
    MUSIC_PIECES_LENGTH,
    SOUND_SOURCE_LENGTH,
    get_scores_with_average,
)

COLUMNS = ["GA" + str(i + 1) for i in range(SOUND_SOURCE_LENGTH)] + ["Average"]


def print_methods() -> None:
    paths = [
        "test/outputs/cross_validations/NCSP_paper/methods/search_tree_0.55_threshold_4_notes__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__select_by_db.csv",
        "test/outputs/cross_validations/NCSP_paper/methods/mean_matching_cosine_similarity_none_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/methods/mean_matching_cosine_similarity_harmonic_0.6-4_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/methods/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__flat_five_priority.csv",
    ]
    scores_table = [
        get_scores_with_average(
            pd.read_csv(
                path,
                dtype=str,
                skiprows=1,
                header=None,
            )
        )
        for path in paths
    ]
    df = pd.DataFrame(
        scores_table,
        index=["Search Tree", "Matching", "Matching-4", "Matching-6"],
        columns=COLUMNS,
    )
    print(
        df.to_latex(
            column_format="lccccc",
            float_format=lambda x: f"{x*100:.3f}",
        )
    )


def print_pcp_calculators() -> None:
    paths = [
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__stft_mags_ln_scaled__E2-D#6__flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__sparse_non_reassign_frequency_ln_scaled__E2-D#6__flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__normal_distribution_comb_filter__sparse_mags_ln_scaled_override_by_8192__E2-D#6__flat_five_priority.csv",
        "test/outputs/cross_validations/NCSP_paper/pcp_calculators/mean_matching_cosine_similarity_harmonic_0.6-6_template_scaled__sparse_ln_scaled__E2-D#6__flat_five_priority.csv",
    ]
    scores_table = [
        get_scores_with_average(
            pd.read_csv(
                path,
                dtype=str,
                skiprows=1,
                header=None,
            )
        )
        for path in paths
    ]
    df = pd.DataFrame(
        scores_table,
        index=["Comb", "ET-scale", "Comb*", "ET-scale*"],
        columns=COLUMNS,
    )
    print(
        df.to_latex(
            column_format="lccccc",
            float_format=lambda x: f"{x*100:.3f}",
        )
    )


if __name__ == "__main__":
    # print_methods()
    print_pcp_calculators()
