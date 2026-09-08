const USER_ID_PATTERN = /^[A-Za-z0-9_-]{8,80}$/;

function userContext(req, res, next) {
  const raw = req.get("X-User-ID");
  if (!raw || !USER_ID_PATTERN.test(raw)) {
    return res.status(400).json({
      error: "INVALID_USER_ID",
      message: "A valid X-User-ID header is required",
    });
  }
  req.userId = raw;
  next();
}

module.exports = { userContext };
