from enterprise_agent import get_project_info


def test_project_info_exposes_first_chapter_stage():
    info = get_project_info()

    assert info.name == "enterprise-agent"
    assert info.version == "0.1.0"
    assert info.stage == "chapter-01-project-setup"

