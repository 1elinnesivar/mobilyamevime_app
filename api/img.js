module.exports = async function handler(req, res) {
  const url = req.query.url;

  if (!url) {
    return res.status(400).end();
  }

  // Sadece mobilyamevime.com resimlerine izin ver
  const allowed =
    url.startsWith('https://www.mobilyamevime.com/') ||
    url.startsWith('https://mobilyamevime.com/');

  if (!allowed) {
    return res.status(403).end();
  }

  try {
    const response = await fetch(url);
    if (!response.ok) {
      return res.status(response.status).end();
    }

    const contentType = response.headers.get('content-type') || 'image/jpeg';
    const buffer = await response.arrayBuffer();

    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.setHeader('Access-Control-Allow-Origin', '*');
    return res.send(Buffer.from(buffer));
  } catch {
    return res.status(502).end();
  }
};
