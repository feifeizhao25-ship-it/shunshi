from sqlalchemy.ext.automap import automap_base
Base = automap_base()
def init_automap():
    Base.prepare(engine, reflect=True)
    return Base
