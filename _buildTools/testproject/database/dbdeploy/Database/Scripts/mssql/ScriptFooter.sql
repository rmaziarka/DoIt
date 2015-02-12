
INSERT INTO changelog (change_number, complete_dt, applied_by, description)
VALUES ($(ScriptId), GetDate(), SYSTEM_USER, '$(ScriptDescription)')

GO

--------------- Fragment ends: $(ScriptName) ---------------