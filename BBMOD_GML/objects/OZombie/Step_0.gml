if (hp <= 0)
{
	dissolve += DELTA_TIME * 0.000001;
	if (dissolve >= 1.0)
	{
		destroy = true;
	}
}