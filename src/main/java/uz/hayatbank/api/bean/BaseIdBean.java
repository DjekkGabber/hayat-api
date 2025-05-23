package uz.hayatbank.api.bean;

import lombok.Data;
import lombok.EqualsAndHashCode;

@EqualsAndHashCode(callSuper = true)
@Data
public class BaseIdBean extends BaseBean{
    private Integer id;
}
