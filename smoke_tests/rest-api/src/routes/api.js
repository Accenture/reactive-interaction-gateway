const express = require("express");
const multer = require("multer");

// const upload = multer({ dest: "uploads/" });
const upload = multer();
const router = express.Router();

router.get("/", (req, res) => {
  const query = req.query.foo;
  if (query && query.bar && query.bar === "baz") {
    return res.send({ msg: "GET QUERY" });
  }

  res.send({ msg: "GET" });
});

router.post("/", upload.any(), (req, res) => {
  const uploads = req.files.map(({ fieldname, originalname, mimetype }) => ({
    fieldname,
    originalname,
    mimetype
  }));
  res.send({ uploads });
});

router.put("/", (req, res) => {
  res.send({ msg: "PUT" });
});

router.patch("/", (req, res) => {
  res.send({ msg: "PATCH" });
});

router.delete("/", (req, res) => {
  res.send({ msg: "DELETE" });
});

router.head("/", (req, res) => {
  res.send();
});

router.options("/", (req, res) => {
  res.send({ msg: "OPTIONS" });
});

module.exports = router;
