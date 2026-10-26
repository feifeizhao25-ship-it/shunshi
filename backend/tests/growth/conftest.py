import pytest
from sqlalchemy.orm import Session

from app.db import init_db, make_engine, make_session_factory


@pytest.fixture()
def growth_session(tmp_path) -> Session:
    engine = make_engine(f"sqlite:///{tmp_path}/growth.db")
    init_db(engine)
    session = make_session_factory(engine)()
    try:
        yield session
        session.commit()
    finally:
        session.close()
        engine.dispose()
